//
//  ContentView.swift
//  BootCamp_Preparation
//
//  Created by Teodor Brankovic on 15.06.24.
//

import SwiftUI

struct ContentView: View {
  @State private var start = Date.now
  
  var body: some View {
    
    TimelineView(.animation) { tl in
      let time = start.distance(to: tl.date)
      /*
       Image(systemName: "figure.walk.circle")
       .font(.system(size: 300))
       .foregroundStyle(.blue)
       .colorEffect(ShaderLibrary.passthrough())
       //.colorEffect(ShaderLibrary.rainbow(.float(time)))
       //.distortionEffect(ShaderLibrary.wave(.float(time)), maxSampleOffset: .zero)
       */
      
      Rectangle()
        .visualEffect { content, proxy in
          content.colorEffect(
            ShaderLibrary.sinebow(
              .float2(proxy.size),
              .float(time)
            )
          )
          
        }
      
    }
  }
  
}


#Preview {
  ContentView()
}
