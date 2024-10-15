//
//  ContentView.swift
//  BootCamp
//
//  Created by Teodor Brankovic on 13.06.24.
//

import SwiftUI

struct ContentView: View {
  @State private var start = Date.now
  
  var body: some View {
    
    TimelineView(.animation) { tl in // redrawing 120 times per second
      let time = start.distance(to: tl.date)
      Rectangle()
        .visualEffect { content, proxy in
          content.colorEffect(
            ShaderLibrary.sinebow(
              .float2(proxy.size),
              .float(time)
            )
          )
        }
    } // end timelineview
    
  }
}

#Preview {
  ContentView()
}
