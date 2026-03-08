import Vision
import Foundation
import Cocoa

let paths = [
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-04 at 22.54.56.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.26.10.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.26.43.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.27.01.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.27.57.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.28.33.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.28.54.png",
    "/Users/viniciuscarvalho/Downloads/Screenshot 2026-03-05 at 19.30.18.png"
]

for path in paths {
    guard let img = NSImage(contentsOfFile: path),
          let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { 
        print("Could not load: \(path)")
        continue 
    }
    
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        print("FILE: \(path.components(separatedBy: "/").last!)\nTEXT: \(text.prefix(150))\n")
    }
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
}
