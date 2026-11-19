import SwiftUI
import WidgetKit
import UserNotifications

@main struct LqFolio:App {
 @StateObject private var p=LfVault()
 var body:some Scene {
  WindowGroup {
   #if DEBUG && targetEnvironment(simulator)
   if ScreenshotLaunch.screen != nil {
    root.defaultAppStorage(ScreenshotLaunch.defaults)
     .transaction { $0.animation = nil; $0.disablesAnimations = true }
   } else {
    root
   }
   #else
   root
   #endif
  }
 }
 private var root:some View {VcRoot().preferredColorScheme(.light).environmentObject(p).tint(VcInk.green).environment(\.locale,Locale(identifier:p.tongue)).onOpenURL{u in p.route(u)}.task{await p.refreshNotifications()}}
}
@MainActor final class LfVault:ObservableObject {
 @Published var state=ZvState()
 @Published var run:ZvRun?
 @Published var tongue=ZrLex.language
 @Published var tab=0
 @Published var jump:Int?
 @Published var message=""
 @Published var busy=false
 @Published var notificationDenied=false
 @Published var daily=false
 @Published var seasonal=false
 @Published var syncOn=false
 var cloudBusy=false
 #if DEBUG && targetEnvironment(simulator)
 var screenshotPresentation:ScreenshotPresentation?
 #endif
 static var folder:URL {
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen != nil {
   let demo = ScreenshotLaunch.folder
   try? FileManager.default.createDirectory(at:demo,withIntermediateDirectories:true)
   return demo
  }
  #endif
  let x=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Folio",isDirectory:true);try? FileManager.default.createDirectory(at:x,withIntermediateDirectories:true);return x
 }
 static var file:URL {folder.appendingPathComponent("course.json")}
 static var pdf:URL {folder.appendingPathComponent("official.pdf")}
 init(){
  #if DEBUG && targetEnvironment(simulator)
  if let screen = ScreenshotLaunch.screen {
   UIView.setAnimationsEnabled(false)
   prepareScreenshot(screen)
   return
  }
  #endif
  daily=ZrLex.defaults.bool(forKey:"daily")
  seasonal=ZrLex.defaults.bool(forKey:"seasonal")
  syncOn=ZrLex.defaults.bool(forKey:"syncOn")
  if let d=try? Data(contentsOf:Self.file),let v=try? JSONDecoder().decode(ZvState.self,from:d){state=v}
 if let d=UserDefaults.standard.data(forKey:"activeBlock"),let x=try? JSONDecoder().decode(ZvRun.self,from:d),x.season==ZrLex.season(){run=x}
 snapshot()
 }
 func save(){
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen != nil { return }
  #endif
  do {try JSONEncoder().encode(state).write(to:Self.file,options:.atomic);if let r=run{UserDefaults.standard.set(try JSONEncoder().encode(r),forKey:"activeBlock")}else{UserDefaults.standard.removeObject(forKey:"activeBlock")};snapshot()}catch{message=zr("saveError")}
 }
 func snapshot(){let d=ZrLex.defaults;d.set(state.reads.count,forKey:"readCount");d.set(state.calls.count,forKey:"callCount");d.set(state.passes(),forKey:"passCount");d.set(ZrLex.season(),forKey:"cachedSeason");d.set(state.streak,forKey:"streak");WidgetCenter.shared.reloadAllTimelines()}
 func changeLanguage(_ x:String){
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen != nil { return }
  #endif
  ZrLex.defaults.set(x,forKey:"tongue");tongue=x;snapshot();Task{await schedule()}
 }
 func mark(_ n:Int){state.reads.insert(n);touch();save()}
 func bookmark(_ n:Int){let k=String(n);state.marks[k]=ZvMark(value:!(state.marks[k]?.value ?? false),time:Date());save()}
 func touch(){state.days.insert(ZrLex.stamp())}
 func record(_ id:Int,_ correct:Bool){touch();if correct{state.calls.insert(id)};state.outcomes[String(id)]=ZvMark(value:correct,time:Date());save()}
 func start(_ n:Int){run=ZvRun(block:n,season:ZrLex.season(),ids:ZrLex.block(n).shuffled());save()}
 func examAnswer(_ x:Int){guard var r=run,r.answers.count<r.ids.count else{return};r.answers.append(x);run=r;save()}
 func complete()->ZvTry? {guard let r=run,r.answers.count==r.ids.count else{return nil};let t=ZvTry(block:r.block,season:r.season,answers:r.answers,ids:r.ids);state.tries.insert(t,at:0);touch();run=nil;save();return t}
 func route(_ u:URL){guard u.scheme=="refereefolio" else{return};if u.host=="law" {let n=Int(u.lastPathComponent) ?? ZrLex.day();if (1...17).contains(n){tab=1;jump=n}}else if u.host=="exam"{tab=2}else{tab=3}}
 func reset(){
  state=ZvState();run=nil
  var defaults=UserDefaults.standard
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen != nil { defaults=ScreenshotLaunch.defaults }
  #endif
  defaults.removeObject(forKey:"learnerName")
  try? FileManager.default.removeItem(at:Self.pdf);try? FileManager.default.removeItem(at:Self.folder.appendingPathComponent("certificate.pdf"));save();message=zr("local")
 }
 func refreshNotifications() async {
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen != nil { return }
  #endif
  let s=await UNUserNotificationCenter.current().notificationSettings();notificationDenied=s.authorizationStatus == .denied;if syncOn{await sync()}
 }
 func permission(_ value:Bool,_ isDaily:Bool) async {
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen != nil { return }
  #endif
  let c=UNUserNotificationCenter.current()
  if value {do {let ok=try await c.requestAuthorization(options:[.alert,.sound,.badge]);if !ok{notificationDenied=true;return}}catch{notificationDenied=true;return}}
  if isDaily{daily=value}else{seasonal=value}
  ZrLex.defaults.set(daily,forKey:"daily");ZrLex.defaults.set(seasonal,forKey:"seasonal");await schedule()
 }
 func schedule() async {let c=UNUserNotificationCenter.current();c.removePendingNotificationRequests(withIdentifiers:["daily-law","season-exam"])
  for (enabled,id,key,h,m,d) in [(daily,"daily-law","ready",9,0,0),(seasonal,"season-exam","newSeason",10,7,1)] where enabled {
   let v=UNMutableNotificationContent();v.title="Laws of the Game";v.body=zr(key);v.sound = .default
   var date=DateComponents();date.hour=h;date.minute=0;if m>0{date.month=m;date.day=d}
   do{try await c.add(UNNotificationRequest(identifier:id,content:v,trigger:UNCalendarNotificationTrigger(dateMatching:date,repeats:true)))}catch{message=zr("denied")}
  }
 }
 func sync() async {}
 func prepare724b6() throws -> Data {
  let value: ZvState = state
  return try JSONEncoder().encode(value)
 }
 func accept724b6(_ data:Data) throws {
  let incoming = try JSONDecoder().decode(ZvState.self, from:data)
  state.blend(incoming);save()
 }

}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotLaunch {
 enum Screen:String,CaseIterable {
  // Indexed launches use this zero-based order on iPhone, iPad and Duo.
  case learn
  case rulebook
  case offsideStudy = "offside-study"
  case practiceHub = "practice-hub"
  case decisionFeedback = "decision-feedback"
  case examResult = "exam-result"
  case courseProgress = "course-progress"
  case certificatePreview = "certificate-preview"
 }

 static let screen:Screen? = {
  let process=ProcessInfo.processInfo
  let args=process.arguments
  func value(after flag:String)->String? {
   guard let i=args.firstIndex(of:flag),args.indices.contains(i+1) else{return nil}
   return args[i+1]
  }
  if args.contains("-ReviewScreen") {return value(after:"-ReviewScreen").flatMap(Screen.init(rawValue:))}
  let environmentFlag=process.environment["APPSTORE_SCREENSHOTS"]?.lowercased()
  guard args.contains("-AppStoreScreenshots") || environmentFlag == "1" || environmentFlag == "true" else{return nil}
  let rawIndex=value(after:"-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
  guard let i=Int(rawIndex),Screen.allCases.indices.contains(i) else{return nil}
  return Screen.allCases[i]
 }()

 static let defaults=UserDefaults(suiteName:"org.verdepitch.codexfolio.screenshots")!
 static let folder=FileManager.default.temporaryDirectory.appendingPathComponent("Folio-Screenshots-\(UUID().uuidString)",isDirectory:true)
}

// Each presenting view consumes its step so dismissing a cover restores the normal flow.
enum ScreenshotPresentation:Equatable {
 case chapter, chapterWithDecision, decision, answerDecision
 case exam(finalAnswer:Int), finishExam(finalAnswer:Int)
 case certificate, generateCertificate
}

extension LfVault {
 private func prepareScreenshot(_ screen:ScreenshotLaunch.Screen) {
  let today=Date()
  let season=ZrLex.season(today)
  let correctAnswers=Dictionary(uniqueKeysWithValues:ZrLex.book.questions.map { ($0.id,$0.correct) })
  let offside=ZrLex.book.questions.first { $0.id == 11 }!
  let wrongOffside=offside.options.firstIndex(of:"Always offside")!

  func mark(_ ids:[Int]) {
   for id in ids {state.marks[String(id)]=ZvMark(value:true,time:today)}
  }
  func recordCorrect(_ ids:ClosedRange<Int>) {
   state.calls=Set(ids)
   for id in ids {state.outcomes[String(id)]=ZvMark(value:true,time:today)}
  }
  func attempt(_ block:Int)->ZvTry {
   let ids=ZrLex.block(block)
   let answers=ids.map { $0 == offside.id ? wrongOffside : correctAnswers[$0]! }
   return ZvTry(block:block,season:season,answers:answers,ids:ids,date:today)
  }

  ScreenshotLaunch.defaults.set(screen == .certificatePreview ? "Alex Morgan" : "",forKey:"learnerName")
  switch screen {
  case .learn:
   state.reads=Set(1...7)
   recordCorrect(1...9)
   state.tries=[attempt(0)]
  case .rulebook:
   tab=1
   state.reads=[1,3,4]
   mark([1,4,11])
  case .offsideStudy:
   tab=1
   state.reads=[11]
   mark([11])
   screenshotPresentation = .chapter
  case .practiceHub:
   tab=2
   state.tries=[attempt(0)]
   state.outcomes[String(offside.id)]=ZvMark(value:false,time:today)
  case .decisionFeedback:
   tab=1
   screenshotPresentation = .chapterWithDecision
  case .examResult:
   tab=2
   let ids=ZrLex.block(1)
   run=ZvRun(block:1,season:season,ids:ids,answers:ids.dropLast().map { correctAnswers[$0]! },seed:1)
   screenshotPresentation = .exam(finalAnswer:wrongOffside)
  case .courseProgress:
   tab=3
   state.reads=Set(1...12)
   recordCorrect(1...14)
   state.tries=[attempt(2),attempt(1),attempt(0)]
   state.days=Set((0..<4).compactMap { offset in
    Calendar.current.date(byAdding:.day,value:-offset,to:today).map { ZrLex.stamp($0) }
   })
  case .certificatePreview:
   tab=3
   state.tries=[attempt(2),attempt(1),attempt(0)]
   screenshotPresentation = .certificate
  }
 }
}
#endif
