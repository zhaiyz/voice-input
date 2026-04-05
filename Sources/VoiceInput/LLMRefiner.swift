import Foundation

class LLMRefiner {
    private var apiBase: String {
        UserDefaults.standard.string(forKey: "llm_api_base") ?? ""
    }
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
    }
    
    private var model: String {
        UserDefaults.standard.string(forKey: "llm_model") ?? "gpt-4o-mini"
    }
    
    private let systemPrompt = """
    You are a conservative speech-to-text correction assistant. Your task is to fix obvious speech recognition errors ONLY.
    
    Rules:
    1. ONLY fix clear homophone errors in Chinese (e.g., "配森" → "Python", "杰森" → "JSON")
    2. ONLY fix obvious English technical terms that were incorrectly converted to Chinese
    3. DO NOT rewrite, polish, or remove any content that appears correct
    4. If the input looks correct, return it EXACTLY as-is
    5. Preserve the original language mix (Chinese + English is fine)
    6. Do not add or remove any information
    7. Return ONLY the corrected text, no explanations
    """
    
    func refine(text: String, completion: @escaping (String?) -> Void) {
        NSLog("[VoiceInput] LLMRefiner.refine called with: '\(text)'")
        NSLog("[VoiceInput] LLM config: apiBase=\(apiBase), apiKey=\(apiKey.isEmpty ? "(empty)" : "(set)"), model=\(model)")
        
        guard !apiBase.isEmpty, !apiKey.isEmpty else {
            NSLog("[VoiceInput] LLMRefiner: missing apiBase or apiKey, returning nil")
            completion(nil)
            return
        }
        
        let baseURL = apiBase.hasSuffix("/") ? apiBase : apiBase + "/"
        let urlString = baseURL + "chat/completions"
        
        guard let url = URL(string: urlString) else {
            NSLog("[VoiceInput] LLMRefiner: invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.0,
            "max_tokens": 1000
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            NSLog("[VoiceInput] LLMRefiner: failed to serialize body: \(error)")
            completion(nil)
            return
        }
        
        NSLog("[VoiceInput] LLMRefiner: sending request to \(urlString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            NSLog("[VoiceInput] LLMRefiner: dataTask completed, error=\(error?.localizedDescription ?? "none"), response=\(response)")
            
            if let error = error {
                NSLog("[VoiceInput] LLMRefiner: network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("[VoiceInput] LLMRefiner: HTTP response status: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200, let data = data else {
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        NSLog("[VoiceInput] LLMRefiner: error response: \(body)")
                    }
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        NSLog("[VoiceInput] LLMRefiner: received refined text: '\(content)'")
                        DispatchQueue.main.async {
                            completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    } else {
                        NSLog("[VoiceInput] LLMRefiner: failed to parse response JSON")
                        if let rawBody = String(data: data, encoding: .utf8) {
                            NSLog("[VoiceInput] LLMRefiner: raw response: \(rawBody)")
                        }
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    NSLog("[VoiceInput] LLMRefiner: failed to decode response: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
        task.resume()
        NSLog("[VoiceInput] LLMRefiner: task started")
    }
    
    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        guard !apiBase.isEmpty, !apiKey.isEmpty else {
            completion(false, "API Base URL and API Key are required")
            return
        }
        
        let baseURL = apiBase.hasSuffix("/") ? apiBase : apiBase + "/"
        let urlString = baseURL + "chat/completions"
        
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid API Base URL")
            return
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": "Hi"]
            ],
            "max_tokens": 10
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false, "Failed to serialize request")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else if let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let errorInfo = json["error"] as? [String: Any],
                          let message = errorInfo["message"] as? String {
                    completion(false, message)
                } else {
                    completion(false, "HTTP \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "Invalid response")
            }
        }
        task.resume()
    }
}
