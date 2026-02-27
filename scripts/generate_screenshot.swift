#!/usr/bin/env swift

import AppKit
import SwiftUI

// MARK: - Mock data

struct MockDevice {
    let icon: String
    let name: String
    let detail: String
    let isActive: Bool
}

let microphones: [MockDevice] = [
    MockDevice(icon: "mic.fill", name: "Elgato Wave:3", detail: "USB", isActive: true),
    MockDevice(icon: "mic.fill", name: "MacBook Pro Microphone", detail: "Built-in", isActive: false),
]

let speakers: [MockDevice] = [
    MockDevice(icon: "speaker.wave.2.fill", name: "CalDigit TS4 Audio - Rear", detail: "USB", isActive: true),
    MockDevice(icon: "speaker.wave.2.fill", name: "MacBook Pro Speakers", detail: "Built-in", isActive: false),
]

let cameras: [MockDevice] = [
    MockDevice(icon: "web.camera", name: "Logitech StreamCam", detail: "External", isActive: true),
    MockDevice(icon: "web.camera", name: "FaceTime HD Camera", detail: "Built-in", isActive: false),
]

// MARK: - Views (matching real app)

struct MockDeviceRow: View {
    let device: MockDevice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.icon)
                .frame(width: 20)
                .foregroundStyle(device.isActive ? .blue : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .lineLimit(1)
                Text(device.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if device.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(device.isActive ? Color.blue.opacity(0.1) : Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MockSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
        }
    }
}

struct MockPopover: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text("Clamshell Mode")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())

                Spacer()

                Text("v1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Device sections
            VStack(alignment: .leading, spacing: 16) {
                MockSection("Microphones") {
                    ForEach(microphones.indices, id: \.self) { i in
                        MockDeviceRow(device: microphones[i])
                    }
                }
                MockSection("Speakers") {
                    ForEach(speakers.indices, id: \.self) { i in
                        MockDeviceRow(device: speakers[i])
                    }
                }
                MockSection("Cameras") {
                    ForEach(cameras.indices, id: \.self) { i in
                        MockDeviceRow(device: cameras[i])
                    }
                }
            }
            .padding(16)

            Spacer(minLength: 0)
            Divider()

            // Bottom bar
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("Support")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                Spacer()

                Text("Quit  ⌘Q")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .background(.background)
    }
}

// MARK: - Capture

let scale: CGFloat = 6
let view = MockPopover()
let hosting = NSHostingView(rootView: view)

// Size to fit content
hosting.frame = NSRect(x: 0, y: 0, width: 320, height: 600)
hosting.layoutSubtreeIfNeeded()
let fittingSize = hosting.fittingSize
hosting.frame = NSRect(origin: .zero, size: fittingSize)

// Render at 3x
let pixelWidth = Int(fittingSize.width * scale)
let pixelHeight = Int(fittingSize.height * scale)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelWidth,
    pixelsHigh: pixelHeight,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap\n", stderr)
    exit(1)
}

bitmap.size = fittingSize

NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.current = context

// Add rounded corners + shadow
let ctx = context.cgContext
let cornerRadius: CGFloat = 12
let rect = CGRect(origin: .zero, size: fittingSize)
let insetRect = rect.insetBy(dx: 8, dy: 8)
let path = CGPath(roundedRect: insetRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Shadow
ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 8, color: CGColor(gray: 0, alpha: 0.25))
ctx.setFillColor(CGColor.white)
ctx.addPath(path)
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0)

// Clip to rounded rect and render
ctx.addPath(path)
ctx.clip()

// Render the SwiftUI view
hosting.cacheDisplay(in: NSRect(origin: .zero, size: fittingSize), to: bitmap)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to create PNG\n", stderr)
    exit(1)
}

let outputPath = "assets/popover.png"
let url = URL(fileURLWithPath: outputPath)
try! pngData.write(to: url)

print("Screenshot saved to \(outputPath) (\(pixelWidth)x\(pixelHeight))")
