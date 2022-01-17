//
//  ContentView.swift
//  Metronome
//
//  Created by Aung Ko Min on 17/1/22.
//

import SwiftUI
import AVFoundation

struct Metronome: View {
    
    @State private var bpm: Double = 60 // beats per minute
    
    var body: some View {
        VStack {
            Text("\(Int(bpm)) bpm").font(.largeTitle).fontWeight(.heavy)
            Spacer()
            TimelineView(.periodic(from: .now, by: 60 / bpm)) { timeline in
                MetronomeBack()
                    .overlay(MetronomePendulum(bpm: bpm, date: timeline.date))
                    .overlay(MetronomeFront(), alignment: .bottom)
            }
            Spacer()
            stepper
        }.padding()
    }
    
    
    private var stepper: some View {
        Stepper("") {
            bpm += 1
        } onDecrement: {
            bpm -= 1
        }.labelsHidden()
    }
}

struct MetronomeBack: View {
    let c1 = Color(red: 0, green: 0.3, blue: 0.5, opacity: 1)
    let c2 = Color(red: 0, green: 0.46, blue: 0.73, opacity: 1)
    
    var body: some View {
        let gradient = LinearGradient(colors: [c1, c2],
                                      startPoint: .topLeading,
                                      endPoint: .bottomTrailing)
        
        RoundedTrapezoid(pct: 0.5, cornerSizes: [CGSize(width: 15, height: 15)])
            .foregroundStyle(gradient)
            .frame(width: 200, height: 350)
    }
}

struct MetronomeFront: View {
    var body: some View {
        RoundedTrapezoid(pct: 0.85, cornerSizes: [.zero, CGSize(width: 10, height: 10)])
            .foregroundStyle(Color(red: 0, green: 0.46, blue: 0.73, opacity: 1))
            .frame(width: 180, height: 100).padding(10)
    }
}


struct MetronomePendulum: View {
    @State var pendulumOnLeft: Bool = false
    @State var bellCounter = 0 // sound bell every 4 beats
    
    let bpm: Double
    let date: Date
    
    var body: some View {
        Pendulum(angle: pendulumOnLeft ? -30 : 30)
            .animation(.easeInOut(duration: 60 / bpm), value: pendulumOnLeft)
            .onChange(of: date) { _ in beat() }
            .onAppear { beat() }
    }
    
    func beat() {
        pendulumOnLeft.toggle() // triggers the animation
        bellCounter = (bellCounter + 1) % 4 // keeps count of beats, to sound bell every 4th
        
        // sound bell or beat?
        if bellCounter == 0 {
            let systemSoundID: SystemSoundID = 1054
            AudioServicesPlaySystemSound(systemSoundID)
        } else {
            let systemSoundID: SystemSoundID = 1052
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }
    
    struct Pendulum: View {
        let angle: Double
        
        var body: some View {
            return Capsule()
                .fill(.red)
                .frame(width: 10, height: 320)
                .overlay(weight)
                .rotationEffect(Angle.degrees(angle), anchor: .bottom)
        }
        
        var weight: some View {
            RoundedRectangle(cornerRadius: 10)
                .fill(.orange)
                .frame(width: 35, height: 35)
                .padding(.bottom, 200)
        }
    }
}

//let bellSound: NSSound? = {
//    guard let url = Bundle.main.url(forResource: "bell", withExtension: "mp3") else { return nil }
//    return NSSound(contentsOf: url, byReference: true)
//}()
//
//let beatSound: NSSound? = {
//    guard let url = Bundle.main.url(forResource: "beat", withExtension: "mp3") else { return nil }
//    return NSSound(contentsOf: url, byReference: true)
//}()
struct RoundedTrapezoid: Shape {
    let pct: CGFloat
    let cornerSizes: [CGSize]
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            let (cs1, cs2, cs3, cs4) = decodeCornerSize()
            
            // Start of path
            let start = CGPoint(x: rect.midX, y: 0)
            
            // width base and top
            let wb = rect.size.width
            let wt = wb * pct
            
            // angles
            let angle: CGFloat = atan(Double(rect.height / ((wb - wt) / 2.0)))
            
            // Control points
            let c1 = CGPoint(x: (wb - wt) / 2.0, y: 0)
            let c2 = CGPoint(x: c1.x + wt, y: 0)
            let c3 = CGPoint(x: wb, y: rect.maxY)
            let c4 = CGPoint(x: 0, y: rect.maxY)
            
            // Points a and b
            let pa2 = CGPoint(x: c2.x - cs2.width, y: 0)
            let pb2 = CGPoint(x: c2.x + CGFloat(cs2.height * tan((.pi/2) - angle)), y: cs2.height)
            
            let pb3 = CGPoint(x: c3.x - cs3.width, y: rect.height)
            let pa3 = CGPoint(x: c3.x - (cs3.height != 0 ? CGFloat(tan(angle) / cs3.height) : 0.0), y: rect.height - cs3.height)
            
            let pa4 = CGPoint(x: c4.x + cs4.width, y: rect.height)
            let pb4 = CGPoint(x: c4.x + (cs4.height != 0 ? CGFloat(tan(angle) / cs4.height) : 0.0), y: rect.height - cs4.height)
            
            let pb1 = CGPoint(x: c1.x + cs1.width, y: 0)
            let pa1 = CGPoint(x: c1.x - CGFloat(cs1.height * tan((.pi/2) - angle)), y: cs1.height)
            
            path.move(to: start)
            
            path.addLine(to: pa2)
            path.addQuadCurve(to: pb2, control: c2)
            
            path.addLine(to: pa3)
            path.addQuadCurve(to: pb3, control: c3)
            
            path.addLine(to: pa4)
            path.addQuadCurve(to: pb4, control: c4)
            
            path.addLine(to: pa1)
            path.addQuadCurve(to: pb1, control: c1)
            
            path.closeSubpath()
        }
    }
    
    func decodeCornerSize() -> (CGSize, CGSize, CGSize, CGSize) {
        if cornerSizes.count == 1 {
            // If only one corner size is provided, use it for all corners
            return (cornerSizes[0], cornerSizes[0], cornerSizes[0], cornerSizes[0])
        } else if cornerSizes.count == 2 {
            // If only two corner sizes are provided, use one for the two top corners,
            // and the other for the two bottom corners
            return (cornerSizes[0], cornerSizes[0], cornerSizes[1], cornerSizes[1])
        } else if cornerSizes.count == 4 {
            // If four corners are provided, use one for each corner
            return (cornerSizes[0], cornerSizes[1], cornerSizes[2], cornerSizes[3])
        } else {
            // In any other case, do not round corners
            return (.zero, .zero, .zero, .zero)
        }
    }
}
