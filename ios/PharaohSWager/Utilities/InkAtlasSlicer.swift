import UIKit

/// Extracts connected ink, not rectangular grid cells: generated sheets can have
/// a weapon reaching into the next cell's empty space. Small detached ornaments
/// follow the nearest figure. The original premultiplied colour/alpha is retained.
enum InkAtlasSlicer {
    private struct Island {
        var count = 0
        var minX: Int
        var minY: Int
        var maxX: Int
        var maxY: Int
        var center: CGPoint { CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2) }
    }
    private static var cache: [String: [Int: UIImage]] = [:]

    static func plate(at index: Int, atlas: String, columns: Int, rows: Int) -> UIImage? {
        if cache[atlas] == nil { cache[atlas] = extract(atlas, columns: columns, rows: rows) }
        return cache[atlas]?[index]
    }

    private static func extract(_ atlas: String, columns: Int, rows: Int) -> [Int: UIImage] {
        guard let source = UIImage(named: atlas)?.cgImage else { return [:] }
        let width = source.width, height = source.height, total = width * height
        var pixels = [UInt8](repeating: 0, count: total * 4)
        let info = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let decoded = pixels.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(data: storage.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info) else { return false }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard decoded else { return [:] }
        var labels = [Int32](repeating: 0, count: total)
        var islands: [Island] = []
        var queue: [Int] = []
        queue.reserveCapacity(total / 3)
        for seed in 0..<total where labels[seed] == 0 && pixels[seed * 4 + 3] > 32 {
            let label = Int32(islands.count + 1)
            var island = Island(minX: seed % width, minY: seed / width, maxX: seed % width, maxY: seed / width)
            queue.removeAll(keepingCapacity: true)
            queue.append(seed)
            labels[seed] = label
            var cursor = 0
            while cursor < queue.count {
                let point = queue[cursor]
                cursor += 1
                let x = point % width, y = point / width
                island.count += 1
                island.minX = min(island.minX, x); island.maxX = max(island.maxX, x)
                island.minY = min(island.minY, y); island.maxY = max(island.maxY, y)
                for neighbor in [x > 0 ? point - 1 : -1, x + 1 < width ? point + 1 : -1,
                                 y > 0 ? point - width : -1, y + 1 < height ? point + width : -1] {
                    if neighbor >= 0, labels[neighbor] == 0, pixels[neighbor * 4 + 3] > 32 {
                        labels[neighbor] = label
                        queue.append(neighbor)
                    }
                }
            }
            islands.append(island)
        }
        let bodies = islands.indices.filter { islands[$0].count > 10_000 }
        // Fail safely to the old character artwork if an atlas no longer fits its contract.
        guard bodies.count == columns * rows else { return [:] }
        var owners: [Int: Int] = [:]
        var bounds: [Int: Island] = [:]
        for body in bodies {
            let center = islands[body].center
            let column = min(columns - 1, Int(center.x) * columns / width)
            let row = min(rows - 1, Int(center.y) * rows / height)
            let slot = row * columns + column
            guard bounds[slot] == nil else { return [:] }
            owners[body + 1] = slot
            bounds[slot] = islands[body]
        }
        for index in islands.indices where islands[index].count <= 10_000 && islands[index].count >= 8 {
            let center = islands[index].center
            guard let closest = bodies.min(by: {
                hypot(islands[$0].center.x - center.x, islands[$0].center.y - center.y)
                < hypot(islands[$1].center.x - center.x, islands[$1].center.y - center.y)
            }), let slot = owners[closest + 1], var bound = bounds[slot] else { continue }
            owners[index + 1] = slot
            bound.minX = min(bound.minX, islands[index].minX); bound.maxX = max(bound.maxX, islands[index].maxX)
            bound.minY = min(bound.minY, islands[index].minY); bound.maxY = max(bound.maxY, islands[index].maxY)
            bounds[slot] = bound
        }
        var result: [Int: UIImage] = [:]
        for (slot, bound) in bounds {
            let left = max(0, bound.minX - 2), top = max(0, bound.minY - 2)
            let right = min(width - 1, bound.maxX + 2), bottom = min(height - 1, bound.maxY + 2)
            let outputWidth = right - left + 1, inkHeight = bottom - top + 1
            let outputHeight = max(380, inkHeight)
            var output = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)
            for y in top...bottom {
                for x in left...right {
                    let input = y * width + x
                    let label = Int(labels[input])
                    guard owners[label] == slot || (label == 0 && pixels[input * 4 + 3] > 0) else { continue }
                    let target = ((y - top + outputHeight - inkHeight) * outputWidth + x - left) * 4
                    for channel in 0..<4 { output[target + channel] = pixels[input * 4 + channel] }
                }
            }
            let data = Data(output)
            if let provider = CGDataProvider(data: data as CFData),
               let image = CGImage(width: outputWidth, height: outputHeight, bitsPerComponent: 8, bitsPerPixel: 32,
                    bytesPerRow: outputWidth * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: info), provider: provider, decode: nil,
                    shouldInterpolate: true, intent: .defaultIntent) {
                result[slot] = UIImage(cgImage: image)
            }
        }
        return result
    }
}
