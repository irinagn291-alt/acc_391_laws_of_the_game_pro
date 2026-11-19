import SwiftUI
import PDFKit
import UniformTypeIdentifiers

enum FpPaper {
 @MainActor static func importFile(_ u:URL)throws {let d=try Data(contentsOf:u,options:.mappedIfSafe);guard d.count<40*1024*1024,let p=PDFDocument(data:d),!p.isLocked,p.pageCount>0 else{throw CocoaError(.fileReadCorruptFile)};try d.write(to:LfVault.pdf,options:.atomic)}
 @MainActor static func make(_ name:String,_ tries:[ZvTry])throws->URL {
  let u=LfVault.folder.appendingPathComponent("certificate.pdf")
  let renderer=UIGraphicsPDFRenderer(bounds:CGRect(x:0,y:0,width:842,height:595))
  let data=renderer.pdfData{ctx in ctx.beginPage();let c=ctx.cgContext
   UIColor(red:0.918,green:0.969,blue:0.941,alpha:1).setFill();c.fill(CGRect(x:0,y:0,width:842,height:595))
   UIColor(red:0.043,green:0.18,blue:0.125,alpha:1).setFill();c.fill(CGRect(x:24,y:24,width:794,height:125))
   func draw(_ s:String,_ rect:CGRect,_ size:CGFloat,_ color:UIColor,_ bold:Bool=false){let style=NSMutableParagraphStyle();style.alignment = .center;(s as NSString).draw(in:rect,withAttributes:[.font:bold ? UIFont.boldSystemFont(ofSize:size):UIFont.systemFont(ofSize:size),.foregroundColor:color,.paragraphStyle:style])}
   draw("LAWS OF THE GAME",CGRect(x:45,y:49,width:752,height:30),15,.white,true)
   draw(zr("certificate"),CGRect(x:40,y:85,width:762,height:50),30,.white,true)
   draw(name,CGRect(x:55,y:182,width:732,height:70),38,.black,true)
   draw(zr("achievement"),CGRect(x:60,y:270,width:722,height:55),18,.darkGray)
   draw("2026/27  •  \(ZrLex.season())",CGRect(x:60,y:325,width:722,height:30),16,.darkGray)
   let season=ZrLex.season();let scores=(0..<3).map{n in "\(zr("block\(n)")): \(tries.filter{$0.block==n && $0.season==season}.map(\.percent).max() ?? 0)%"}.joined(separator:"   /   ")
   draw(scores,CGRect(x:55,y:367,width:732,height:40),14,.darkGray,true)
   let dateFormat=DateFormatter();dateFormat.locale=Locale(identifier:ZrLex.language);dateFormat.dateStyle = .long
   draw(dateFormat.string(from:Date()),CGRect(x:60,y:420,width:722,height:30),14,.darkGray)
   draw(zr("disclaimer"),CGRect(x:65,y:478,width:712,height:68),12,.darkGray)
  }
  try data.write(to:u,options:.atomic);return u
 }
}
struct FpCertificate:View {
 @EnvironmentObject var p:LfVault
 @Environment(\.dismiss) var dismiss
 @AppStorage("learnerName") private var name=""
 @State private var output:URL?
 @State private var failed=false
 @State private var generation=0
 var body:some View {ScrollView{VStack(spacing:24){Image(systemName:p.state.passes()==3 ? "checkmark.seal.fill":"lock.circle").font(.system(size:74)).foregroundStyle(VcInk.green);Text(zr("certificate")).font(.system(.largeTitle,design:.serif,weight:.bold)).multilineTextAlignment(.center)
 if p.state.passes()==3{Text(zr("achievement")).multilineTextAlignment(.center);TextField(zr("name"),text:$name).textContentType(.name).textFieldStyle(.roundedBorder).onChange(of:name){_,v in if v.count>70{name=String(v.prefix(70))}}.accessibilityIdentifier("certificateName");Button(zr("export")){generatePDF()}.buttonStyle(.borderedProminent).disabled(name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("createPDF");if let output{ShareLink(item:output){Label(zr("certificate"),systemImage:"square.and.arrow.up")}.accessibilityIdentifier("sharePDF");FpNative(url:output).id(generation).frame(height:310)}}else{Text(zr("locked")).multilineTextAlignment(.center)}
 Text(zr("disclaimer")).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
 }.padding(28).frame(maxWidth:760).frame(maxWidth:.infinity)}.navigationTitle(zr("certificate")).navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.topBarTrailing){Button(zr("close")){dismiss()}}}.alert(zr("exportError"),isPresented:$failed){Button(zr("close"),role:.cancel){}}
 #if DEBUG && targetEnvironment(simulator)
 .onAppear {
  guard p.screenshotPresentation == .generateCertificate else{return}
  p.screenshotPresentation=nil
  generatePDF()
 }
 #endif
 }
 private func generatePDF() {
  do {
   output=try FpPaper.make(name.trimmingCharacters(in:.whitespacesAndNewlines),p.state.tries)
   generation+=1
  } catch {
   failed=true
  }
 }
}
struct FpNative:UIViewRepresentable {
 let url:URL
 func makeUIView(context:Context)->PDFView{let v=PDFView();v.autoScales=true;v.displayMode = .singlePageContinuous;v.document=PDFDocument(url:url);return v}
 func updateUIView(_ uiView:PDFView,context:Context){}
}
struct FpReader:View {
 @Environment(\.dismiss) var dismiss
 @State private var page=1
 @State private var query=""
 @State private var pdf=PDFDocument(url:LfVault.pdf)
 @State private var contents=false
 var body:some View {VStack(spacing:0){HStack{Image(systemName:"magnifyingglass");TextField(zr("search"),text:$query).onSubmit{NotificationCenter.default.post(name:.init("FolioFind"),object:query)};Button{NotificationCenter.default.post(name:.init("FolioFind"),object:query)}label:{Image(systemName:"arrow.right.circle")}}.padding();FpNavigable(document:pdf,page:$page);HStack{Button{page=max(1,page-1)}label:{Image(systemName:"chevron.left")};Spacer();Text("\(zr("page")) \(page) / \(pdf?.pageCount ?? 0)").font(.caption);Spacer();Button{page=min(pdf?.pageCount ?? 1,page+1)}label:{Image(systemName:"chevron.right")}}.padding()}.navigationTitle(zr("official")).navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.topBarLeading){Button(zr("close")){dismiss()}};ToolbarItem(placement:.topBarTrailing){Button(zr("pdfContents")){contents=true}}}.sheet(isPresented:$contents){NavigationStack{List{if let root=pdf?.outlineRoot{ForEach(0..<root.numberOfChildren,id:\.self){i in if let node=root.child(at:i),let dest=node.destination,let pg=dest.page,let doc=pdf{Button(node.label ?? "\(i+1)"){page=doc.index(for:pg)+1;contents=false}}}}else{ForEach(0..<(pdf?.pageCount ?? 0),id:\.self){i in Button("\(zr("page")) \(i+1)"){page=i+1;contents=false}}}}.navigationTitle(zr("pdfContents")).toolbar{Button(zr("close")){contents=false}}}}}
}
struct FpNavigable:UIViewRepresentable {
 let document:PDFDocument?
 @Binding var page:Int
 func makeCoordinator()->Bridge{Bridge(self)}
 func makeUIView(context:Context)->PDFView {let v=PDFView();v.document=document;v.autoScales=true;context.coordinator.view=v;context.coordinator.observe();return v}
 func updateUIView(_ v:PDFView,context:Context){context.coordinator.owner=self;if let d=document,let pg=d.page(at:page-1),v.currentPage != pg{v.go(to:pg)}}
 final class Bridge:NSObject {var owner:FpNavigable;weak var view:PDFView?;var tokens:[NSObjectProtocol]=[];init(_ p:FpNavigable){owner=p}
 func observe(){tokens.append(NotificationCenter.default.addObserver(forName:.PDFViewPageChanged,object:view,queue:.main){[weak self]_ in guard let s=self,let v=s.view,let p=v.currentPage,let d=v.document else{return};let n=d.index(for:p)+1;if s.owner.page != n{s.owner.page=n}})
 tokens.append(NotificationCenter.default.addObserver(forName:.init("FolioFind"),object:nil,queue:.main){[weak self]n in guard let s=self,let term=n.object as? String,!term.isEmpty,let d=s.view?.document else{return};let matches=d.findString(term,withOptions:.caseInsensitive);if let first=matches.first{s.view?.setCurrentSelection(first,animate:true);s.view?.go(to:first)}})}
 deinit{tokens.forEach{NotificationCenter.default.removeObserver($0)}}
 }
}
