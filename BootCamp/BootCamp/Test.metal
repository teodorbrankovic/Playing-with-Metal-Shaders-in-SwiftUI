//
//  Test.metal
//  BootCamp
//
//  Created by Teodor Brankovic on 13.06.24.
//


/*
 - very C like language
 - half4 -> 4 because of RGBA, half variante of float, double etc.
 - must be [[stitchable]]
 - args... -> extra values of YOUR choosing
 */
#include <metal_stdlib>
using namespace metal;

/*
 take color and do nothing with it
 call up function in SwiftUI? -> ShaderLibrary.passthrough()     automatically done by SwiftUI at runtime !
 */

[[stitchable]] half4 passtrough (float2 pos, half4 color) {
  return color;
}

/*
 add color red to pixel, respect opacity as it is
 */
[[stitchable]] half4 recolor (float2 pos, half4 color) {
  return half4 (1, 0, 0, color.a); // 1 for red, 0 for green, 0 for blue, color.a for opacity to stay at is is -> makes a picture red
}

/*
 pos.x / pos.y -1/1, 1/2, 1/3 ... etc for red
 0 for green
 pos.y / pos.x again for green
 WE GET A GRADIENT EFFECT
 */
[[stitchable]] half4 gradient (float2 pos, half4 color) {
  return half4(pos.x / pos.y, 0, pos.y / pos.x, color.a);
}


/*
 NOW ACCEPTING CUSTOM VALUES WITH args ...
 Shaders are beeing clipped of the View
 */


[[stitchable]] half4 rainbow (float2 pos, half4 color, float time) {
  float angle = atan2(pos.y, pos.x) + time; // angle top left corner to the pixel we are trying to draw + time = angle changes constantly
  return half4(sin(angle), sin(angle + 2), sin(angle + 4), color.a);
}


[[stitchable]] float2 wave (float2 pos, float time) {
  pos.y += sin(time*5 + pos.y/20) * 5; // move it up and down slightly based on time + pos.y, moving constantly
  return pos;
}

/*
 [[stitchable]] float2 wave (float2 pos, float time, float2 size) {
 float2 distance = pos / size; // how far are we from the left edge
 pos.y += sin(time*5 + pos.y/20) * distance * 10; // move it up and down slightly based on time + pos.y, moving constantly
 return pos;
 }
 */

/*
 In that shader, the first two parameters are required by SwiftUI: it will automatically pass
 in the position of the view, along with its current color. The second and remaining parameters are
 all created by us, and need to be sent in manually. In this case, I’m passing in the size I want the
 checkerboard squares to be.
 */
[[ stitchable ]] half4 checkerboard(float2 position, half4 currentColor, float size, half4 newColor) {
  uint2 posInChecks = uint2(position.x / size, position.y / size);
  bool isColor = (posInChecks.x ^ posInChecks.y) & 1;
  return isColor ? newColor * currentColor.a : half4(0.0, 0.0, 0.0, 0.0);
}

/*
 First, you can make shaders that animate by placing them inside a TimelineView and
 sending in a date value. For example, we could create a start date and send the difference
 between that start date and the current date to power a noise shader.
 */
[[ stitchable ]] half4 noise(float2 position, half4 currentColor, float time) {
  float value = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
  return half4(value, value, value, 1) * currentColor.a;
}


/// A shader that generates multiple twisting and turning lines that cycle through colors.
///
/// This shader calculates how far each pixel is from one of 10 lines.
/// Each line has its own undulating color and position based on various
/// sine waves, so the pixel's color is calculating by starting from black
/// and adding in a little of each line's color based on its distance.
///
/// - Parameter position: The user-space coordinate of the current pixel.
/// - Parameter color: The current color of the pixel.
/// - Parameter size: The size of the whole image, in user-space.
/// - Parameter time: The number of elapsed seconds since the shader was created
/// - Returns: The new pixel color.
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

[[ stitchable ]] half4 lightGrid(float2 position, half4 color, float2 size, float time, float density, float speed, float groupSize, float brightness) {
    // Calculate our aspect ratio.
    half aspectRatio = size.x / size.y;

    // Calculate our coordinate in UV space, 0 to 1.
    half2 uv = half2(position / size);

    // Make sure we can create the effect roughly equally no
    // matter what aspect ratio we're in.
    uv.x *= aspectRatio;

    // If it's not transparent…
    if (color.a > 0.0h) {
        // STEP 1: Split the grid up into groups based on user input.
        half2 point = uv * density;

        // STEP 2: Calculate the color variance for each group
        // pick two numbers that are unlikely to repeat.
        half2 nonRepeating = half2(12.9898h, 78.233h);

        // Assign this pixel to a group number.
        half2 groupNumber = floor(point);

        // Multiply our group number by the non-repeating
        // numbers, then add them together.
        half sum = dot(groupNumber, nonRepeating);

        // Calculate the sine of our sum to get a range
        // between -1 and 1.
        half sine = sin(sum);

        // Multiply the sine by a big, non-repeating number
        // so that even a small change will result in
        // a big color jump.
        float hugeNumber = float(sine) * 43758.5453;

        // Calculate the sine of our time and our huge number
        // and map it to the range 0...1.
        half variance = (0.5h * sin(time + hugeNumber)) + 0.5h;

        // Adjust the color variance by the provided speed.
        half acceleratedVariance = speed * variance;


        // STEP 3: Calculate the final color for this group.
        // Select a base color to work from.
        half3 baseColor = half3(3.0h, 1.5h, 0.0h);

        // Apply our variation to the base color, factoring in time.
        half3 variedColor = baseColor + acceleratedVariance + time;

        // Calculate the sine of our varied color so it has
        // the range -1 to 1.
        half3 variedColorSine = sin(variedColor);

        // Adjust the sine to lie in the range 0...1.
        half3 newColor = (0.5h * variedColorSine) + 0.5h;


        // STEP 4: Now we know the color, calculate the color pulse
        // Start by moving down and left a little to create black
        // lines at intersection points.
        half2 adjustedGroupSize = M_PI_H * 2.0h * groupSize * (point - (0.25h / groupSize));

        // Calculate the sine of our group size, then adjust it
        // to lie in the range 0...1.
        half2 groupSine = (0.5h * sin(adjustedGroupSize)) + 0.5h;

        // Use the sine to calculate a pulsating value between
        // 0 and 1, making our group fluctuate together.
        half2 pulse = smoothstep(0.0h, 1.0h, groupSine);

        // Calculate the final color by combining the pulse
        // strength and user brightness with the color
        // for this square.
        return half4(newColor * pulse.x * pulse.y * brightness, 1.0h) * color.a;
    } else {
        // Use the current (transparent) color.
        return color;
    }
}


