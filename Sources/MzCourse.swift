import Foundation

struct ZyLeaf:Codable,Identifiable,Hashable { let id:Int; let slug:String; let title:String; let body:String }
struct ZyCall:Codable,Identifiable { let id:Int;let chapter:Int;let prompt:String;let options:[String];let reason:String;let correct:Int }
struct ZyText:Decodable { let ui:[String:String];let chapters:[ZyLeaf];let questions:[ZyCall] }
enum ZrLex {
 static let group = "group.org.verdepitch.codexfolio"
 static var defaults:UserDefaults { UserDefaults(suiteName:group) ?? .standard }
 static let tongues = ["en","de","es","it","pt-BR","fr"]
 static let names = ["English","Deutsch","Español","Italiano","Português (Brasil)","Français"]
 static var language:String {
  #if DEBUG && targetEnvironment(simulator) && !FOLIO_WIDGET
  if ScreenshotLaunch.screen != nil { return "en" }
  #endif
  if let s=defaults.string(forKey:"tongue"),tongues.contains(s){return s}
  for s in Locale.preferredLanguages { if s.hasPrefix("pt"){return "pt-BR"};if let l=tongues.first(where:{s.hasPrefix($0)}){return l} }; return "en"
 }
 static let bundles:[String:ZyText] = Dictionary(uniqueKeysWithValues:tongues.compactMap { l in
  guard let u=Bundle.main.url(forResource:l,withExtension:"json"), let d=try? Data(contentsOf:u), let x=try? JSONDecoder().decode(ZyText.self,from:d) else{return nil};return (l,x)
 })
 static var book:ZyText { bundles[language] ?? bundles["en"]! }
 static func word(_ key:String)->String {book.ui[key] ?? key}
 static func day(_ date:Date=Date())->Int { let c=Calendar.current;let n=c.ordinality(of:.day,in:.era,for:date) ?? 1; return (n % 17)+1 }
 static func season(_ date:Date=Date())->String {let c=Calendar.current;let y=c.component(.year,from:date)-(c.component(.month,from:date)<7 ? 1:0);return "\(y)/\(String(y+1).suffix(2))"}
 static func stamp(_ date:Date=Date())->String {let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.calendar=Calendar(identifier:.gregorian);f.dateFormat="yyyy-MM-dd";return f.string(from:date)}
 static func block(_ n:Int)->[Int] { switch n {case 0:return Array(1...6);case 1:return Array(7...11);default:return Array(12...17)} }
}
func zr(_ k:String)->String {ZrLex.word(k)}
struct ZvMark:Codable {var value:Bool;var time:Date}
struct ZvTry:Codable,Identifiable {var id=UUID().uuidString;var block:Int;var season:String;var answers:[Int];var ids:[Int];var date=Date()
 var score:Int {zip(ids,answers).filter{ id,answer in ZrLex.book.questions.first(where:{$0.id==id})?.correct == answer}.count}
 var percent:Int {ids.isEmpty ? 0:Int((Double(score)/Double(ids.count)*100).rounded(.down))}
 var passed:Bool {score*100 >= ids.count*80 && !ids.isEmpty}
}
struct ZvRun:Codable,Identifiable {var id=UUID().uuidString;var block:Int;var season:String;var ids:[Int];var answers:[Int]=[];var seed:Int=Int.random(in:1...5000)
 func choices(_ q:ZyCall)->[Int] {let x=(seed+q.id)%q.options.count;return Array(q.options.indices).map{($0+x)%q.options.count}}
}
struct ZvState:Codable {
 var reads:Set<Int>=[];var calls:Set<Int>=[];var outcomes:[String:ZvMark]=[:];var days:Set<String>=[];var marks:[String:ZvMark]=[:];var tries:[ZvTry]=[]
 mutating func blend(_ other:Self) {
  reads.formUnion(other.reads);calls.formUnion(other.calls);days.formUnion(other.days)
  for (k,v) in other.outcomes {if outcomes[k] == nil || outcomes[k]!.time<v.time{outcomes[k]=v}}
  for (k,v) in other.marks {if marks[k] == nil || marks[k]!.time<v.time{marks[k]=v}}
  let known=Set(tries.map(\.id));tries += other.tries.filter{!known.contains($0.id)};tries.sort{$0.date>$1.date}
 }
 func passes(_ season:String=ZrLex.season())->Int {Set(tries.filter{$0.season==season && $0.passed}.map(\.block)).count}
 var wrong:Set<Int> {Set(outcomes.filter{!$0.value.value}.compactMap{Int($0.key)})}
 var streak:Int {let c=Calendar.current; var day=Date(); if !days.contains(ZrLex.stamp(day)){day=c.date(byAdding:.day,value:-1,to:day)!};var n=0
  while days.contains(ZrLex.stamp(day)) {n+=1;day=c.date(byAdding:.day,value:-1,to:day)!};return n}
}
