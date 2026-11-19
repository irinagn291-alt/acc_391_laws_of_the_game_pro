import SwiftUI
import UniformTypeIdentifiers

enum VcInk {static let green=Color(red:0.082,green:0.486,blue:0.306);static let dark=Color(red:0.043,green:0.18,blue:0.125);static let mint=Color(red:0.918,green:0.969,blue:0.941);static let paper=Color(uiColor:.systemBackground)}
struct VcRoot:View {
 @EnvironmentObject var p:LfVault
 @State private var selected:ZyLeaf?
 @State private var settings=false
 var body:some View {
  TabView(selection:$p.tab){
   pane("home",0,"house.fill"){VhDesk(open:{selected=$0})}
   pane("laws",1,"book.closed"){VlIndex(open:{selected=$0})}
   pane("practice",2,"sportscourt"){VpDrill()}
   pane("progress",3,"chart.bar.xaxis"){VgTrack()}
  }.id(p.tongue).fullScreenCover(item:$selected){x in NavigationStack{VlRead(leaf:x)}}
   .sheet(isPresented:$settings){NavigationStack{VsOptions()}}
   .onChange(of:p.jump){_,v in if let v {selected=ZrLex.book.chapters.first{$0.id==v};p.jump=nil}}
   .overlay(alignment:.top){if !p.message.isEmpty{Text(p.message).font(.callout).padding().background(.regularMaterial,in:RoundedRectangle(cornerRadius:16)).padding().onTapGesture{p.message=""}.task(id:p.message){try? await Task.sleep(for:.seconds(7));p.message=""}}}
   #if DEBUG && targetEnvironment(simulator)
   .onAppear {
    switch p.screenshotPresentation {
    case .chapter:
     p.screenshotPresentation=nil
    case .chapterWithDecision:
     p.screenshotPresentation = .decision
    default:
     return
    }
    selected=ZrLex.book.chapters.first { $0.id == 11 }
   }
   #endif
 }
 func pane<T:View>(_ key:String,_ n:Int,_ image:String,@ViewBuilder _ content:()->T)->some View {
  NavigationStack {content().navigationTitle(n==0 ? "Laws of the Game":zr(key)).navigationBarTitleDisplayMode(n==0 ? .inline:.large).toolbar {ToolbarItem(placement:.topBarTrailing){Button{settings=true}label:{Image(systemName:"slider.horizontal.3")}.accessibilityLabel(zr("settings")).accessibilityIdentifier("settings")}}}
  .tabItem{Label(zr(key),systemImage:image)}.tag(n)
 }
}
struct VpPitch:View {
 var body:some View {GeometryReader{g in Path{p in let r=CGRect(x:16,y:12,width:g.size.width-32,height:g.size.height-24);p.addRect(r);p.move(to:CGPoint(x:r.midX,y:r.minY));p.addLine(to:CGPoint(x:r.midX,y:r.maxY));p.addEllipse(in:CGRect(x:r.midX-27,y:r.midY-27,width:54,height:54));p.addRect(CGRect(x:r.minX,y:r.midY-43,width:38,height:86));p.addRect(CGRect(x:r.maxX-38,y:r.midY-43,width:38,height:86))}.stroke(.white.opacity(0.13),lineWidth:1.5)}}
}
struct VhDesk:View {
 @EnvironmentObject var p:LfVault
 let open:(ZyLeaf)->Void
 var daily:ZyLeaf {ZrLex.book.chapters.first{$0.id==ZrLex.day()}!}
 var body:some View {
 ScrollView{VStack(alignment:.leading,spacing:26){
  HStack{Text(zr("edition")).font(.caption.weight(.bold)).tracking(2).foregroundStyle(VcInk.green);Spacer();Image(systemName:"soccerball").foregroundStyle(VcInk.green)}
  Text(zr("headline")).font(.system(.largeTitle,design:.serif,weight:.bold)).foregroundStyle(VcInk.dark).fixedSize(horizontal:false,vertical:true)
  Button{open(daily)}label:{ZStack(alignment:.leading){VpPitch().padding(.leading,100);VStack(alignment:.leading,spacing:15){Label(zr("daily"),systemImage:"sun.max").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.8));Text(String(format:"%02d",daily.id)).font(.system(size:54,weight:.light,design:.serif));Text(daily.title).font(.title2.bold());HStack{Text(zr("read")).font(.subheadline.weight(.semibold));Image(systemName:"arrow.up.right")}}.padding(24)}.foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:250,alignment:.leading).background(VcInk.dark,in:RoundedRectangle(cornerRadius:24))}.buttonStyle(.plain).accessibilityIdentifier("dailyLaw")
  VStack(alignment:.leading,spacing:15){Text(zr("course")).font(.headline);HStack(spacing:0){metric(p.state.reads.count,17,"chapters");metric(p.state.calls.count,17,"episodes");metric(p.state.passes(),3,"blocks")};ProgressView(value:Double(p.state.reads.count+p.state.calls.count+p.state.passes()),total:37).tint(VcInk.green)}.padding(20).background(VcInk.mint,in:RoundedRectangle(cornerRadius:20))
  VStack(alignment:.leading,spacing:12){HStack{Image(systemName:"sportscourt.fill").font(.title2).foregroundStyle(VcInk.green);Spacer();Text("01 — 17").font(.caption.monospaced()).foregroundStyle(.secondary)};Text(zr("quick")).font(.title2.bold());Text(zr("quickBody")).foregroundStyle(.secondary);Button{p.tab=2}label:{HStack{Text(zr("begin"));Spacer();Image(systemName:"arrow.right")}.padding(15).background(VcInk.green,in:RoundedRectangle(cornerRadius:12)).foregroundStyle(.white)}.buttonStyle(.plain).accessibilityIdentifier("startPractice")}.padding(20).background(VcInk.paper,in:RoundedRectangle(cornerRadius:20)).overlay(RoundedRectangle(cornerRadius:20).stroke(VcInk.green.opacity(0.18)))
  Text(zr("original")).font(.footnote).foregroundStyle(.secondary)
 }.padding(22).frame(maxWidth:850).frame(maxWidth:.infinity)}.background(Color(uiColor:.systemGroupedBackground))
 }
 func metric(_ n:Int,_ total:Int,_ key:String)->some View{VStack(alignment:.leading,spacing:5){Text("\(n)").font(.title.bold())+Text(" / \(total)").font(.caption);Text(zr(key)).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading)}
}
struct VlIndex:View {
 @EnvironmentObject var p:LfVault
 let open:(ZyLeaf)->Void
 #if DEBUG && targetEnvironment(simulator)
 @State private var text=ScreenshotLaunch.screen == .offsideStudy ? "Offside" : ""
 #else
 @State private var text=""
 #endif
 @State private var saved=false
 @State private var importing=false
 @State private var pdf=false
 @State private var error=false
 var leaves:[ZyLeaf]{ZrLex.book.chapters.filter{(!saved || p.state.marks[String($0.id)]?.value == true) && (text.isEmpty || ($0.title+" "+$0.body).localizedCaseInsensitiveContains(text))}}
 var body:some View {
 List{
  Section{Picker(zr("laws"),selection:$saved){Text(zr("all")).tag(false);Text(zr("saved")).tag(true)}.pickerStyle(.segmented).listRowBackground(Color.clear)}
  if leaves.isEmpty{ContentUnavailableView(zr("empty"),systemImage:"bookmark",description:Text(zr("savedEmpty")))}
  ForEach(leaves){l in Button{open(l)}label:{HStack(spacing:16){Text(String(format:"%02d",l.id)).font(.system(.title3,design:.serif)).foregroundStyle(VcInk.green).frame(width:34);VStack(alignment:.leading,spacing:4){Text(l.title).font(.headline).foregroundStyle(.primary);Text(l.body.components(separatedBy:"\n")[0]).font(.caption).lineLimit(1).foregroundStyle(.secondary)};Spacer();if p.state.reads.contains(l.id){Image(systemName:"checkmark.circle.fill").foregroundStyle(VcInk.green)};if p.state.marks[String(l.id)]?.value == true{Image(systemName:"bookmark.fill").foregroundStyle(VcInk.green)};Image(systemName:"chevron.right").font(.caption).foregroundStyle(.tertiary)}.padding(.vertical,9)}.accessibilityIdentifier("chapter\(l.id)")}
  Section(zr("official")){Text(zr("importInfo")).font(.footnote);Link(zr("source"),destination:URL(string:"https://www.theifab.com/laws-of-the-game-documents/")!);Button(zr("import")){importing=true};if FileManager.default.fileExists(atPath:LfVault.pdf.path){Button(zr("openPDF")){pdf=true}}}
 }.searchable(text:$text,prompt:zr("search")).fileImporter(isPresented:$importing,allowedContentTypes:[.pdf]){result in do {let u=try result.get();let a=u.startAccessingSecurityScopedResource();defer{if a{u.stopAccessingSecurityScopedResource()}};try FpPaper.importFile(u);pdf=true}catch{self.error=true}}
 .fullScreenCover(isPresented:$pdf){NavigationStack{FpReader()}}.alert(zr("pdfError"),isPresented:$error){Button(zr("close"),role:.cancel){}}
 }
}
struct VlRead:View {
 let leaf:ZyLeaf
 @EnvironmentObject var p:LfVault
 @Environment(\.dismiss) var dismiss
 @State private var quiz=false
 var body:some View {ScrollView{VStack(alignment:.leading,spacing:24){Text("\(zr("law").uppercased()) \(String(format:"%02d",leaf.id)) • 2026/27").font(.caption.bold()).tracking(2).foregroundStyle(VcInk.green);Text(leaf.title).font(.system(.largeTitle,design:.serif,weight:.bold));VpPitch().frame(height:130).background(VcInk.dark,in:RoundedRectangle(cornerRadius:18));Text(zr("study")).font(.headline);Text(leaf.body).font(.title3).lineSpacing(7).textSelection(.enabled);Button{p.mark(leaf.id)}label:{Label(zr(p.state.reads.contains(leaf.id) ? "studied":"mark"),systemImage:p.state.reads.contains(leaf.id) ? "checkmark.circle.fill":"checkmark.circle")}.buttonStyle(.borderedProminent).accessibilityIdentifier("markStudied");Button(zr("check")){quiz=true}.buttonStyle(.bordered);Divider();Text(zr("original")).font(.footnote).foregroundStyle(.secondary);Link(zr("source"),destination:URL(string:"https://www.theifab.com/laws/latest/\(leaf.slug)/")!)}.padding(26).frame(maxWidth:780).frame(maxWidth:.infinity)}.navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.topBarLeading){Button(zr("close")){dismiss()}};ToolbarItem(placement:.topBarTrailing){Button{p.bookmark(leaf.id)}label:{Image(systemName:p.state.marks[String(leaf.id)]?.value == true ? "bookmark.fill":"bookmark")}.accessibilityLabel(zr("saved")).accessibilityIdentifier("bookmark")}}.fullScreenCover(isPresented:$quiz){NavigationStack{VdSession(run:ZvRun(block:-1,season:ZrLex.season(),ids:[leaf.id]))}}
 #if DEBUG && targetEnvironment(simulator)
 .onAppear {
  guard p.screenshotPresentation == .decision else{return}
  p.screenshotPresentation = .answerDecision
  quiz=true
 }
 #endif
 }
}
struct VpDrill:View {
 @EnvironmentObject var p:LfVault
 @State private var session:ZvRun?
 var body:some View {ScrollView{VStack(alignment:.leading,spacing:22){Text(zr("quick")).font(.system(.title,design:.serif,weight:.bold));Text(zr("quickBody")).foregroundStyle(.secondary);Button{session=ZvRun(block:-1,season:ZrLex.season(),ids:Array(ZrLex.book.questions.map(\.id).shuffled().prefix(5)))}label:{Label(zr("free"),systemImage:"play.fill").frame(maxWidth:.infinity).padding(13)}.buttonStyle(.borderedProminent).accessibilityIdentifier("freePractice");Button{session=ZvRun(block:-1,season:ZrLex.season(),ids:Array(p.state.wrong).shuffled())}label:{Label(zr("mistakes"),systemImage:"arrow.counterclockwise")}.disabled(p.state.wrong.isEmpty);if p.state.wrong.isEmpty{Text(zr("noMistakes")).font(.caption).foregroundStyle(.secondary)};Divider();Text(zr("exam")+" · "+ZrLex.season()).font(.title2.bold());Text(zr("examInfo")).font(.subheadline).foregroundStyle(.secondary)
 if let r=p.run {Button{session=r}label:{Label(zr("resume"),systemImage:"play.circle.fill")}.buttonStyle(.borderedProminent).accessibilityIdentifier("resumeExam")}
 ForEach(0..<3){n in Button{if p.run==nil{p.start(n)};session=p.run}label:{HStack(spacing:16){Text("0\(n+1)").font(.title2.monospaced()).foregroundStyle(VcInk.green);VStack(alignment:.leading,spacing:5){Text(zr("block\(n)")).font(.headline);Text("\(ZrLex.block(n).count) \(zr("questions")) • 80%").font(.caption).foregroundStyle(.secondary)};Spacer();if p.state.tries.contains(where:{$0.block==n && $0.season==ZrLex.season() && $0.passed}){Image(systemName:"checkmark.seal.fill").foregroundStyle(VcInk.green)}else{Image(systemName:"chevron.right").foregroundStyle(VcInk.green)}}.padding(18).background(VcInk.mint,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(.plain).disabled(p.run != nil).accessibilityIdentifier("examBlock\(n)")}
 }.padding(24).frame(maxWidth:800).frame(maxWidth:.infinity)}.fullScreenCover(item:$session){r in NavigationStack{VdSession(run:r)}}
 #if DEBUG && targetEnvironment(simulator)
 .onAppear {
  guard case let .exam(finalAnswer)? = p.screenshotPresentation else{return}
  p.screenshotPresentation = .finishExam(finalAnswer:finalAnswer)
  session=p.run
 }
 #endif
 }
}
struct VdSession:View {
 @EnvironmentObject var p:LfVault
 @Environment(\.dismiss) var dismiss
 @State var run:ZvRun
 @State private var chosen:Int?
 @State private var practiceAnswers:[Int]=[]
 @State private var result:ZvTry?
 @State private var finished=false
 #if DEBUG && targetEnvironment(simulator)
 @State private var revealScreenshotFeedback=false
 private static let screenshotDecisionID="screenshotDecision"
 private enum ScreenshotDecisionFraming:Equatable,Sendable {case asLaidOut, top, bottom}
 #endif
 var exam:Bool{run.block>=0}
 var index:Int{exam ? run.answers.count:practiceAnswers.count}
 var question:ZyCall? {guard index<run.ids.count else{return nil};return ZrLex.book.questions.first{$0.id==run.ids[index]}}
 var body:some View {
  #if DEBUG && targetEnvironment(simulator)
  if ScreenshotLaunch.screen == .decisionFeedback {
   ScrollViewReader { proxy in session(feedbackScroll:proxy) }
  } else {
   session()
  }
  #else
  session()
  #endif
 }
 private func session(feedbackScroll:ScrollViewProxy?=nil)->some View {
 ScrollView{VStack(alignment:.leading,spacing:24){
 if finished {Image(systemName:(result?.passed ?? true) ? "checkmark.seal":"book").font(.system(size:55)).foregroundStyle(VcInk.green);Text(zr(exam ? (result?.passed == true ? "pass":"fail"):"practiceDone")).font(.largeTitle.bold());if let t=result{Text("\(t.score) / \(t.ids.count) · \(t.percent)%").font(.title)}
 ForEach(Array(run.ids.enumerated()),id:\.offset){i,id in if let q=ZrLex.book.questions.first(where:{$0.id==id}){VStack(alignment:.leading,spacing:9){Text(q.prompt).font(.headline);let a=exam ? (result?.answers ?? []):practiceAnswers;if i<a.count{Text(q.options[a[i]]).foregroundStyle(a[i]==q.correct ? VcInk.green:Color.orange)};Label(q.options[q.correct],systemImage:"checkmark.circle").foregroundStyle(VcInk.green);Text(q.reason).font(.subheadline).foregroundStyle(.secondary)}.padding().frame(maxWidth:.infinity,alignment:.leading).background(VcInk.mint,in:RoundedRectangle(cornerRadius:14))}}
 Button(zr("close")){dismiss()}.buttonStyle(.borderedProminent)
 }else if let q=question{
 HStack{Text(zr(exam ? "exam":"practice").uppercased()).font(.caption.bold()).tracking(1.5);Spacer();Text("\(index+1) / \(run.ids.count)").monospacedDigit()}.foregroundStyle(VcInk.green);ProgressView(value:Double(index),total:Double(run.ids.count));Text("\(zr("law")) \(q.chapter)").font(.subheadline).foregroundStyle(.secondary)
 #if DEBUG && targetEnvironment(simulator)
 if let feedbackScroll {
  let hasFeedback=chosen != nil
  VStack(alignment:.leading,spacing:24){decisionContent(q)}
   .id(Self.screenshotDecisionID)
   .onGeometryChange(for:ScreenshotDecisionFraming?.self) { geometry in
    guard hasFeedback,let viewport=geometry.bounds(of:.scrollView),viewport.height>0 else{return nil}
    guard geometry.size.height>viewport.maxY else{return .asLaidOut}
    // Keep the prompt below the navigation bar when the full decision cannot fit.
    return geometry.size.height<=viewport.height ? .bottom : .top
   } action: { framing in
    guard revealScreenshotFeedback,let framing else{return}
    revealScreenshotFeedback=false
    switch framing {
    case .asLaidOut: break
    case .top: feedbackScroll.scrollTo(Self.screenshotDecisionID,anchor:.top)
    case .bottom: feedbackScroll.scrollTo(Self.screenshotDecisionID,anchor:.bottom)
    }
   }
 } else {
  decisionContent(q)
 }
 #else
 decisionContent(q)
 #endif
 if let v=chosen {
  Button(index==run.ids.count-1 ? zr("finish"):zr("next")){advance(v)}.buttonStyle(.borderedProminent).accessibilityIdentifier("nextQuestion")
 }
 }
 }.padding(25).frame(maxWidth:780).frame(maxWidth:.infinity)}.navigationTitle(zr(exam ? "exam":"practice")).navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.topBarLeading){Button(zr(exam ? "leave":"close")){dismiss()}}}
 #if DEBUG && targetEnvironment(simulator)
 .onAppear {
  switch p.screenshotPresentation {
  case .answerDecision:
   guard let q=question else{return}
   p.screenshotPresentation=nil
   run.seed=1
   revealScreenshotFeedback=true
   choose(q.correct,for:q)
  case let .finishExam(finalAnswer):
   p.screenshotPresentation=nil
   advance(finalAnswer)
  default:
   break
  }
 }
 #endif
 }
 @ViewBuilder private func decisionContent(_ q:ZyCall)->some View {
  Text(q.prompt).font(.system(.title,design:.serif,weight:.semibold)).fixedSize(horizontal:false,vertical:true)
  Text(zr("decision")).font(.headline)
  ForEach(run.choices(q),id:\.self){v in Button{choose(v,for:q)}label:{HStack{Text(q.options[v]).multilineTextAlignment(.leading);Spacer();Image(systemName:chosen==v ? "largecircle.fill.circle":"circle")}.padding(18).foregroundStyle(chosen==v ? .white:VcInk.dark).background(chosen==v ? VcInk.green:VcInk.mint,in:RoundedRectangle(cornerRadius:16))}.buttonStyle(.plain).accessibilityIdentifier("option\(v)")}
  if let v=chosen,!exam {
   VStack(alignment:.leading,spacing:10){
    Label(zr(v==q.correct ? "correct":"review"),systemImage:v==q.correct ? "checkmark.circle.fill":"book")
     .font(.headline).foregroundStyle(VcInk.green)
    Text(q.reason)
   }.padding().background(VcInk.mint,in:RoundedRectangle(cornerRadius:16))
  }
 }
 private func choose(_ answer:Int,for question:ZyCall) {
  guard chosen==nil || exam else{return}
  chosen=answer
  if !exam{p.record(question.id,answer==question.correct)}
 }
 func advance(_ v:Int){if exam{p.examAnswer(v);run=p.run ?? run;if run.answers.count==run.ids.count{result=p.complete();finished=true}}else{practiceAnswers.append(v);if practiceAnswers.count==run.ids.count{finished=true}};chosen=nil}
}
struct VgTrack:View {
 @EnvironmentObject var p:LfVault
 @State private var certificate=false
 var body:some View {ScrollView{VStack(alignment:.leading,spacing:22){HStack{VStack(alignment:.leading){Text("\(p.state.streak)").font(.system(size:58,weight:.light,design:.serif));Text(zr("days")).font(.subheadline)};Spacer();Image(systemName:"leaf.circle").font(.system(size:64)).foregroundStyle(VcInk.green)}.padding(24).background(VcInk.mint,in:RoundedRectangle(cornerRadius:20));Text(zr("course")).font(.title2.bold());VhDesk(open:{_ in}).metric(p.state.reads.count,17,"chapters");ProgressView(value:Double(p.state.reads.count),total:17);VhDesk(open:{_ in}).metric(p.state.calls.count,17,"episodes");ProgressView(value:Double(p.state.calls.count),total:17);VhDesk(open:{_ in}).metric(p.state.passes(),3,"blocks");ProgressView(value:Double(p.state.passes()),total:3)
 Button{certificate=true}label:{HStack{Image(systemName:"checkmark.seal").font(.title);VStack(alignment:.leading){Text(zr("certificate")).font(.headline);Text(zr(p.state.passes()==3 ? "export":"locked")).font(.caption)};Spacer();Image(systemName:p.state.passes()==3 ? "arrow.up.right":"lock")}.padding(20).foregroundStyle(.white).background(VcInk.dark,in:RoundedRectangle(cornerRadius:20))}.buttonStyle(.plain).accessibilityIdentifier("certificate")
 Text(zr("history")).font(.title2.bold());if p.state.tries.isEmpty{Text(zr("historyEmpty")).foregroundStyle(.secondary)}
 ForEach(p.state.tries.prefix(30)){t in HStack{VStack(alignment:.leading,spacing:4){Text(zr("block\(t.block)"));Text(t.date,style:.date).font(.caption).foregroundStyle(.secondary);Text(t.season).font(.caption)};Spacer();Text("\(t.percent)%").font(.title3.bold());Image(systemName:t.passed ? "checkmark.circle.fill":"arrow.counterclockwise").foregroundStyle(VcInk.green)}.padding(.vertical,8)}
 }.padding(24).frame(maxWidth:800).frame(maxWidth:.infinity)}.sheet(isPresented:$certificate){NavigationStack{FpCertificate()}}
 #if DEBUG && targetEnvironment(simulator)
 .onAppear {
  guard p.screenshotPresentation == .certificate else{return}
  p.screenshotPresentation = .generateCertificate
  certificate=true
 }
 #endif
 }
}
struct VsOptions:View {
 @EnvironmentObject var p:LfVault
 @Environment(\.dismiss) var dismiss
 @State private var reset=false
 var body:some View {Form{
 Section(zr("language")){Picker(zr("language"),selection:Binding(get:{p.tongue},set:{p.changeLanguage($0)})){ForEach(Array(ZrLex.tongues.enumerated()),id:\.element){i,l in Text(ZrLex.names[i]).tag(l)}}}
 Section(zr("reminders")){Text(zr("notifyInfo")).font(.footnote);Toggle(zr("daily"),isOn:Binding(get:{p.daily},set:{v in Task{await p.permission(v,true)}}));Toggle(zr("seasonReminder"),isOn:Binding(get:{p.seasonal},set:{v in Task{await p.permission(v,false)}}));if p.notificationDenied{Text(zr("denied")).font(.footnote);Link(zr("system"),destination:URL(string:UIApplication.openSettingsURLString)!)}}
   F724b6(encode: p.prepare724b6, apply: p.accept724b6)
 Section(zr("privacy")){Text(zr("privacyText")).font(.footnote);Text(zr("original")).font(.footnote);Link(zr("source"),destination:URL(string:"https://www.theifab.com/laws-of-the-game-documents/")!)}
 Section{Button(zr("reset"),role:.destructive){reset=true}}
 }.navigationTitle(zr("settings")).toolbar{ToolbarItem(placement:.topBarTrailing){Button(zr("close")){dismiss()}}}.confirmationDialog(zr("resetInfo"),isPresented:$reset,titleVisibility:.visible){Button(zr("reset"),role:.destructive){p.reset()}}}
}

import UniformTypeIdentifiers

private struct F724b6:View {
 let encode:() throws -> Data
 let apply:(Data) throws -> Void
 @Environment(\.locale) private var language
 @State private var exporting=false
 @State private var importing=false
 @State private var document:Envelope?
 @State private var status=""
 private var labels:[String] {
  let words:[String:[String]]=["en":["Export file","Import file","File imported"],"de":["Datei exportieren","Datei importieren","Datei importiert"],"fr":["Exporter un fichier","Importer un fichier","Fichier importé"],"es":["Exportar archivo","Importar archivo","Archivo importado"],"pt":["Exportar arquivo","Importar arquivo","Arquivo importado"],"it":["Esporta file","Importa file","File importato"]]
  return words[language.language.languageCode?.identifier ?? "en"] ?? words["en"]!
 }
 private struct Envelope:FileDocument {
  static var readableContentTypes:[UTType]{[.json]}
  let contents:Data
  init(contents:Data){self.contents=contents}
  init(configuration:ReadConfiguration)throws{guard let data=configuration.file.regularFileContents else{throw CocoaError(.fileReadCorruptFile)};contents=data}
  func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper{FileWrapper(regularFileWithContents:contents)}
 }
 var body:some View {
  VStack(alignment:.leading,spacing:12){
   Button {do {let payload=try encode();let obj=try JSONSerialization.jsonObject(with:payload,options:[.fragmentsAllowed])
    document=Envelope(contents:try JSONSerialization.data(withJSONObject:["format":"org.verdepitch.codexfolio/1","payload":obj]));status="";exporting=true
   }catch{status=error.localizedDescription}} label:{Label(labels[0],systemImage:"square.and.arrow.up")}.buttonStyle(.borderless)
   Button {importing=true} label:{Label(labels[1],systemImage:"square.and.arrow.down")}.buttonStyle(.borderless)
   if !status.isEmpty{Text(status).font(.footnote).foregroundStyle(.secondary)}
  }.fileExporter(isPresented:$exporting,document:document,contentType:.json,defaultFilename:"Laws of the Game - Referee practice"){
   if case .failure(let error)=$0{status=error.localizedDescription}
  }.fileImporter(isPresented:$importing,allowedContentTypes:[.json]){
   do {let url=try $0.get();let scoped=url.startAccessingSecurityScopedResource();defer{if scoped{url.stopAccessingSecurityScopedResource()}}
    guard let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize,size>0,size<100_000_000 else{throw CocoaError(.fileReadTooLarge)}
    let raw=try JSONSerialization.jsonObject(with:Data(contentsOf:url))
    guard let envelope=raw as? [String:Any],envelope["format"] as? String=="org.verdepitch.codexfolio/1",let payload=envelope["payload"] else{throw CocoaError(.fileReadCorruptFile)}
    try apply(JSONSerialization.data(withJSONObject:payload,options:[.fragmentsAllowed]));status=labels[2]
   }catch{status=error.localizedDescription}
  }
 }
}
