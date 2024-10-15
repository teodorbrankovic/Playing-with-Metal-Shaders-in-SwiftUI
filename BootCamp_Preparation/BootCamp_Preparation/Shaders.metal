//
//  Shaders.metal
//  BootCamp_Preparation
//
//  Created by Teodor Brankovic on 15.06.24.
//

#include <metal_stdlib>
using namespace metal;

//hal4 (how much storage you want to give your float number!)

[[stitchable]] half4 passthrough(float2 pos, half4 color) {
  return color;
}


[[stitchable]] half4 recolor(float2 pos, half4 color) {
  return half4(1, 0, 0, color.a);
}


[[stitchable]] half4 invertAlpha(float2 pos, half4 color) {
  return half4(1, 0, 0, 1 - color.a);
}
 

[[stitchable]] half4 gradient(float2 pos, half4 color) {
  return half4(pos.x / pos.y, 0, pos.y / pos.x, color.a);
}

[[stitchable]] half4 rainbow(float2 pos, half4 color, float time) {
  float angle = atan2(pos.y, pos.x) + time;
  
  return half4(sin(angle), sin(angle + 2), sin(angle + 4), color.a);
}

[[stitchable]] float2 wave(float2 pos, float time) {
  pos.y += sin(time * 5 + pos.y / 20) * 5;
  return pos;
}



[[ stitchable ]] half4 sinebow(float2 position, half4 color, float2 size, float time) {
  // Calculate our aspect ratio.
  half aspectRatio = size.x / size.y;
  
  // Calculate our coordinate in UV space, -1 to 1.
  half2 uv = half2(position / size.x) * 2.0h - 1.0h;
  
  // Make sure we can create the effect roughly equally no
  // matter what aspect ratio we're in.
  uv.x /= aspectRatio;
  
  // Calculate the overall wave movement.
  half wave = sin(uv.x + time);
  
  // Square that movement, and multiply by a large number
  // to make the peaks and troughs be nice and big.
  wave *= wave * 50.0h;
  
  // Assume a black color by default.
  half3 waveColor = half3(0.0h);
  
  // Create 10 lines in total.
  for (half i = 0.0h; i < 10.0h; i++) {
    // The base brightness of this pixel is 1%, but we
    // need to factor in the position after our wave
    // calculation is taken into account. The abs()
    // call ensures negative numbers become positive,
    // so we care about the absolute distance to the
    // nearest line, rather than ignoring values that
    // are negative.
    half luma = abs(1.0h / (100.0h * uv.y + wave));
    
    // This calculates a second sine wave that's unique
    // to each line, so we get waves inside waves.
    half y = sin(uv.x * sin(time) + i * 0.2h + time);
    
    // This offsets each line by that second wave amount,
    // so the waves move non-uniformly.
    uv.y += 0.05h * y;
    
    // Our final color is based on fixed red and blue
    // values, but green fluctuates much more so that
    // the overall brightness varies more randomly.
    // The * 0.5 + 0.5 part ensures the sin() values
    // are between 0 and 1 rather than -1 and 1.
    half3 rainbow = half3(
                          sin(i * 0.3h + time) * 0.5h + 0.5h,
                          sin(i * 0.3h + 2.0h + sin(time * 0.3h) * 2.0h) * 0.5h + 0.5h,
                          sin(i * 0.3h + 4.0h) * 0.5h + 0.5h
                          );
    
    // Add that to the current wave color, ensuring that
    // pixels receive some brightness from all lines.
    waveColor += rainbow * luma;
  }
  
  // Send back the finished color, taking into account the
  // current alpha value.
  return half4(waveColor, 1.0h) * color.a;
}
