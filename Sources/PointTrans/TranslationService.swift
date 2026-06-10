import Foundation

class TranslationService {
    
    static let shared = TranslationService()
    
    private init() {}
    
    /// Translates a word using Google Translate (instant web API) with customizable direction and API mirror.
    func translateWithGoogle(word: String, direction: String) async -> String? {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else { return nil }
        
        let sl = direction == "zh-to-en" ? "zh-CN" : "en"
        let tl = direction == "zh-to-en" ? "en" : "zh-CN"
        
        // Read custom mirror from settings (helpful for mainland China users without proxy)
        var mirror = UserDefaults.standard.string(forKey: "googleMirrorUrl") ?? ""
        mirror = mirror.trimmingCharacters(in: .whitespacesAndNewlines)
        if mirror.isEmpty {
            mirror = "https://translate.googleapis.com"
        } else {
            // Remove trailing slash if present
            if mirror.hasSuffix("/") {
                mirror.removeLast()
            }
            // Add scheme if missing
            if !mirror.hasPrefix("http://") && !mirror.hasPrefix("https://") {
                mirror = "https://" + mirror
            }
        }
        
        guard let encodedWord = trimmedWord.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(mirror)/translate_a/single?client=gtx&sl=\(sl)&tl=\(tl)&dt=t&q=\(encodedWord)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Responsive timeout
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Google Translate response format is: [[["translation", "original", null, null, 1]], null, "en"]
            if let json = try JSONSerialization.jsonObject(with: data) as? [Any],
               let firstArray = json.first as? [Any] {
                
                var fullTranslation = ""
                for part in firstArray {
                    if let partArray = part as? [Any],
                       let translatedSegment = partArray.first as? String {
                        fullTranslation += translatedSegment
                    }
                }
                
                if !fullTranslation.isEmpty {
                    return fullTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return nil
        } catch {
            print("[TranslationService] Google Translate Error: \(error)")
            // Provide a localization-aware network warning for timeouts
            return Localization.string(for: "net_error_google")
        }
    }
    
    /// Translates a word in its context using AI (Gemini or OpenAI-compatible API)
    func translateWithAI(word: String, context: String, direction: String) async -> String? {
        let provider = UserDefaults.standard.string(forKey: "aiProvider") ?? "gemini"
        
        let prompt = Localization.translationPrompt(word: word, context: context, direction: direction)
        
        if provider == "gemini" {
            return await callGeminiAPI(prompt: prompt)
        } else {
            return await callOpenAIAPI(prompt: prompt)
        }
    }
    
    private func callGeminiAPI(prompt: String) async -> String? {
        let apiKey = UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
        let model = UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-1.5-flash"
        
        guard !apiKey.isEmpty else {
            return Localization.string(for: "ai_key_warning")
        }
        
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { return nil }
        
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                print("[TranslationService] Gemini Error Code: \(httpResponse.statusCode), body: \(errorMsg)")
                return "⚠️ Gemini API Error: \(httpResponse.statusCode)"
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return "⚠️ Gemini response format error"
        } catch {
            print("[TranslationService] Gemini network error: \(error)")
            return "⚠️ Gemini connection timeout / block"
        }
    }
    
    private func callOpenAIAPI(prompt: String) async -> String? {
        let apiKey = UserDefaults.standard.string(forKey: "openaiApiKey") ?? ""
        let endpoint = UserDefaults.standard.string(forKey: "openaiEndpoint") ?? "https://api.openai.com/v1/chat/completions"
        let model = UserDefaults.standard.string(forKey: "openaiModel") ?? "gpt-4o-mini"
        
        guard !apiKey.isEmpty else {
            return Localization.string(for: "ai_key_warning")
        }
        
        guard let url = URL(string: endpoint) else { return nil }
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                print("[TranslationService] OpenAI Error Code: \(httpResponse.statusCode), body: \(errorMsg)")
                return "⚠️ API Error: \(httpResponse.statusCode)"
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let text = message["content"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return "⚠️ API response format error"
        } catch {
            print("[TranslationService] OpenAI network error: \(error)")
            return "⚠️ API connection timeout / block"
        }
    }
}
