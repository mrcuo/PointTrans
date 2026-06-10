import Cocoa
import Vision
import CoreGraphics

struct ExtractedText {
    let word: String
    let context: String
}

class TextExtractor {
    
    /// Requests screen capture permissions (standard macOS API)
    static func requestPermissions() -> Bool {
        return CGRequestScreenCaptureAccess()
    }
    
    /// Extracts the word (English or Chinese depending on translation mode) directly under the mouse cursor,
    /// along with its containing line/sentence as context.
    static func extractWordAtCursor(mode: String) -> ExtractedText? {
        // 1. Get mouse position in Cocoa coordinates (origin at bottom-left of the primary display)
        let mousePos = NSEvent.mouseLocation

        // 2. Find screen containing the mouse to convert to CG coordinates
        // CG coordinates: origin at top-left of the primary screen
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }
        
        let primaryScreenHeight = screens[0].frame.height
        let cgMouseY = primaryScreenHeight - mousePos.y
        let cgMouseX = mousePos.x

        // Define capture bounds centered around the mouse cursor
        let width: CGFloat = 400
        let height: CGFloat = 80
        let captureRect = CGRect(
            x: cgMouseX - (width / 2),
            y: cgMouseY - (height / 2),
            width: width,
            height: height
        )

        // 3. Capture screen contents in memory
        guard let cgImage = CGWindowListCreateImage(
            captureRect,
            .excludeDesktopElements,
            kCGNullWindowID,
            .nominalResolution
        ) else {
            print("[TextExtractor] Failed to capture screen image. Screen Recording permission might be missing.")
            return nil
        }

        // 4. Set up and run Vision OCR
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        
        // Setup OCR languages dynamically
        if mode == "zh-to-en" {
            request.recognitionLanguages = ["zh-Hans", "en-US"]
        } else {
            request.recognitionLanguages = ["en-US"]
        }
        
        request.usesLanguageCorrection = true

        do {
            try requestHandler.perform([request])
        } catch {
            print("[TextExtractor] OCR error: \(error)")
            return nil
        }

        guard let results = request.results, !results.isEmpty else {
            return nil
        }

        // The mouse coordinate inside the captured image is exactly the center of the image.
        // In Vision's normalized coordinate system, (0,0) is bottom-left, (1,1) is top-right.
        // Therefore, the mouse is exactly at (0.5, 0.5).
        let targetPoint = CGPoint(x: 0.5, y: 0.5)

        var bestWord: String? = nil
        var bestContext: String? = nil
        var closestDistance: CGFloat = CGFloat.infinity

        for observation in results {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let lineText = candidate.string
            let lineBox = observation.boundingBox

            // Expand the height box slightly to capture letters that go below baseline (g, y, p, etc.)
            let verticalPadding: CGFloat = 0.05
            let expandedLineBox = CGRect(
                x: lineBox.origin.x,
                y: lineBox.origin.y - verticalPadding,
                width: lineBox.size.width,
                height: lineBox.size.height + (verticalPadding * 2)
            )

            // If the cursor is vertically and horizontally inside this line's box
            if expandedLineBox.contains(targetPoint) {
                let tokenizedWords = tokenize(lineText, mode: mode)
                
                for wordInfo in tokenizedWords {
                    do {
                        if let wordBox = try candidate.boundingBox(for: wordInfo.range) {
                            let box = wordBox.boundingBox
                            
                            // Check if cursor x-coordinate is within word's horizontal bounds
                            if targetPoint.x >= box.minX && targetPoint.x <= box.maxX {
                                bestWord = wordInfo.word
                                bestContext = lineText
                                break
                            }
                            
                            // Otherwise record the closest word by center distance
                            let centerX = box.midX
                            let distance = abs(targetPoint.x - centerX)
                            if distance < closestDistance {
                                closestDistance = distance
                                bestWord = wordInfo.word
                                bestContext = lineText
                            }
                        }
                    } catch {
                        print("[TextExtractor] Error getting bounding box for word: \(error)")
                    }
                }
                
                if bestWord != nil {
                    break
                }
            }
        }

        // Clean and filter the word (ensure it matches the active translation mode)
        if let word = bestWord {
            if mode == "zh-to-en" {
                // Chinese-to-English: Filter characters to make sure it contains Chinese
                let cleanedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedWord.isEmpty && isChineseWord(cleanedWord) {
                    return ExtractedText(word: cleanedWord, context: bestContext ?? word)
                }
            } else {
                // English-to-Chinese: Filter characters to make sure it is English
                let cleanedWord = word.trimmingCharacters(in: CharacterSet.letters.inverted)
                if !cleanedWord.isEmpty && isEnglishWord(cleanedWord) {
                    return ExtractedText(word: cleanedWord, context: bestContext ?? word)
                }
            }
        }

        return nil
    }

    /// Check if the word is composed of English alphabetical characters.
    private static func isEnglishWord(_ word: String) -> Bool {
        let pattern = "^[a-zA-Z]+[a-zA-Z'-]*$"
        return word.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Check if the word contains Chinese Han characters.
    private static func isChineseWord(_ word: String) -> Bool {
        let pattern = "\\p{Han}"
        return word.range(of: pattern, options: .regularExpression) != nil
    }

    /// Tokenizes a line into words and their corresponding Ranges in the String.
    private static func tokenize(_ text: String, mode: String) -> [(word: String, range: Range<String.Index>)] {
        var words: [(word: String, range: Range<String.Index>)] = []
        
        if mode == "zh-to-en" {
            // Apple's .byWords option natively splits Chinese sentences into words using linguistic analysis
            text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byWords) { substring, range, _, _ in
                if let word = substring {
                    words.append((word: word, range: range))
                }
            }
            
            // Fallback to characters if word segmentation returns empty
            if words.isEmpty {
                text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byComposedCharacterSequences) { substring, range, _, _ in
                    if let word = substring {
                        words.append((word: word, range: range))
                    }
                }
            }
        } else {
            // Standard English word segmentation
            text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byWords) { substring, range, _, _ in
                if let word = substring {
                    words.append((word: word, range: range))
                }
            }
        }
        
        return words
    }
}
