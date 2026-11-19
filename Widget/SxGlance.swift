import WidgetKit
import SwiftUI

struct WqEntry:TimelineEntry {let date:Date;var read:Int=ZrLex.defaults.integer(forKey:"readCount");var calls:Int=ZrLex.defaults.integer(forKey:"callCount");var pass:Int {ZrLex.defaults.string(forKey:"cachedSeason")==ZrLex.season(date) ? ZrLex.defaults.integer(forKey:"passCount"):0};var streak:Int=ZrLex.defaults.integer(forKey:"streak")}
struct WqFeed:TimelineProvider {
 func placeholder(in context:Context)->WqEntry{WqEntry(date:Date())}
 func getSnapshot(in context:Context,completion:@escaping(WqEntry)->Void){completion(WqEntry(date:Date()))}
 func getTimeline(in context:Context,completion:@escaping(Timeline<WqEntry>)->Void){let c=Calendar.current;let start=c.startOfDay(for:Date());let entries=(0..<3).compactMap{c.date(byAdding:.day,value:$0,to:start)}.map{WqEntry(date:$0)};completion(Timeline(entries:entries,policy:.atEnd))}
}
struct WqSurface:View {
 var entry:WqEntry
 @Environment(\.widgetFamily) var family
 var leaf:ZyLeaf{ZrLex.book.chapters.first{$0.id==ZrLex.day(entry.date)}!}
 var url:URL{URL(string:"refereefolio://law/\(leaf.id)")!}
 var body:some View {
  Group {switch family {
   case .accessoryCircular:VStack(spacing:1){Image(systemName:"book.closed");Text("\(leaf.id)").font(.headline)}.accessibilityLabel(zr("ready"))
   case .accessoryRectangular:VStack(alignment:.leading){Label(zr("daily"),systemImage:"book.closed").font(.caption);Text(leaf.title).font(.headline).lineLimit(1)}
   case .accessoryInline:Text("\(zr("law")) \(leaf.id): \(leaf.title)")
   default:VStack(alignment:.leading,spacing:10){HStack{Image(systemName:"book.closed.fill");Text(zr("daily")).font(.caption.bold());Spacer()}.foregroundStyle(Color.green);Text("\(String(format:"%02d",leaf.id))").font(.system(size:family == .systemSmall ? 28:34,weight:.light,design:.serif));Text(leaf.title).font(.headline).lineLimit(2).minimumScaleFactor(0.75)
    if family != .systemSmall {Divider();HStack{Label("\(entry.pass)/3",systemImage:"checkmark.seal");Text(zr("blocks")).font(.caption);Spacer();Label("\(entry.streak)",systemImage:"leaf")}.font(.subheadline)}
    if family == .systemLarge {HStack{Text(zr("chapters"));Spacer();Text("\(entry.read)/17")};ProgressView(value:Double(entry.read),total:17);HStack{Text(zr("episodes"));Spacer();Text("\(entry.calls)/17")};ProgressView(value:Double(entry.calls),total:17);Link(destination:URL(string:"refereefolio://progress")!){Label(zr(entry.pass==3 ? "certificate":"course"),systemImage:"arrow.up.right")}.font(.caption)}
   }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
  }}.containerBackground(for:.widget){Color(red:0.918,green:0.969,blue:0.941)}.widgetURL(url)
 }
}
#if FOLIO_WIDGET
@main struct WqBundle:Widget {
 let kind="FolioDailyLaw"
 var body:some WidgetConfiguration {StaticConfiguration(kind:kind,provider:WqFeed()){WqSurface(entry:$0)}.configurationDisplayName(zr("widgetName")).description(zr("widgetDesc")).supportedFamilies([.systemSmall,.systemMedium,.systemLarge,.accessoryCircular,.accessoryRectangular,.accessoryInline])}
}
#endif
