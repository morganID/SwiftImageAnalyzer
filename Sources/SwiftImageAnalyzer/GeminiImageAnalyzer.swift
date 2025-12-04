import Foundation

// MARK: - Gemini Image Analyzer

/// Image analyzer implementation using Google's Gemini Vision API
public final class GeminiImageAnalyzer: ImageAnalyzer {
    public let name = "Gemini Vision API"

    /// API key for Google Gemini
    private let apiKey: String

    /// Base URL for Gemini API
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent")!

    /// URLSession for network requests
    private let session: URLSession

    /// Initialize with API key
    /// - Parameter apiKey: Your Google AI API key
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    /// Initialize with API key and custom URLSession
    /// - Parameters:
    ///   - apiKey: Your Google AI API key
    ///   - session: Custom URLSession (useful for testing)
    public init(apiKey: String, session: URLSession) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - ImageAnalyzer Protocol

    public func analyze(
        _ input: ImageInput,
        configuration: ImageAnalysisConfiguration
    ) async throws -> ImageAnalysisResult {
        let startTime = Date()

        // Load image data
        let (imageData, mimeType) = try await ImageAnalyzerUtilities.loadImageData(from: input)

        // Validate image data
        guard !imageData.isEmpty else {
            throw ImageAnalysisError.invalidImageData
        }

        // Create API request
        let result = try await performGeminiRequest(
            imageData: imageData,
            mimeType: mimeType,
            prompt: configuration.prompt,
            temperature: configuration.temperature,
            maxTokens: configuration.maxTokens
        )

        let processingTime = Date().timeIntervalSince(startTime)
        let metadata = AnalysisMetadata(
            mimeType: mimeType,
            imageSize: imageData.count,
            analyzerName: name,
            processingTime: processingTime
        )

        return ImageAnalysisResult(
            rawResponse: result.rawResponse,
            parsedData: result.parsedData,
            metadata: metadata
        )
    }

    // MARK: - Private Methods

    private func performGeminiRequest(
        imageData: Data,
        mimeType: String,
        prompt: String,
        temperature: Double?,
        maxTokens: Int?
    ) async throws -> GeminiResponse {
        let url = URL(string: "\(baseURL.absoluteString)?key=\(apiKey)")!

        let base64String = imageData.base64EncodedString()

        // Build request body
        var requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": mimeType,
                                "data": base64String
                            ]
                        ]
                    ]
                ]
            ]
        ]

        // Add generation config if specified
        var generationConfig: [String: Any] = [:]
        if let temperature = temperature {
            generationConfig["temperature"] = temperature
        }
        if let maxTokens = maxTokens {
            generationConfig["maxOutputTokens"] = maxTokens
        }
        if !generationConfig.isEmpty {
            requestBody["generationConfig"] = generationConfig
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Perform request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageAnalysisError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        // Check for HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ImageAnalysisError.apiError(statusCode: httpResponse.statusCode, message: message)
            }
            throw ImageAnalysisError.apiError(statusCode: httpResponse.statusCode, message: "Unknown API error")
        }

        // Parse response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImageAnalysisError.parsingError("Invalid JSON response")
        }

        // Check for API errors in response body
        if let error = jsonResponse["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw ImageAnalysisError.apiError(statusCode: 200, message: message)
        }

        // Extract text from candidates
        guard let candidates = jsonResponse["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw ImageAnalysisError.parsingError("Could not extract text from Gemini response")
        }

        // Try to parse as JSON if the response looks like JSON
        let parsedData = parseJSONResponse(text)

        return GeminiResponse(rawResponse: text, parsedData: parsedData)
    }

    private func parseJSONResponse(_ text: String) -> [String: Any]? {
        let cleanedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\\"", with: "\"") // Unescape quotes

        // Remove markdown code block markers if present
        var jsonText = cleanedText
        if jsonText.hasPrefix("```json") {
            jsonText = String(jsonText.dropFirst(7))
        }
        if jsonText.hasPrefix("```") {
            jsonText = String(jsonText.dropFirst(3))
        }
        if jsonText.hasSuffix("```") {
            jsonText = String(jsonText.dropLast(3))
        }
        jsonText = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to parse as JSON
        guard let jsonData = jsonText.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        return jsonObject
    }
}

// MARK: - Private Types

private struct GeminiResponse {
    let rawResponse: String
    let parsedData: [String: Any]?
}

// MARK: - Convenience Extensions

extension GeminiImageAnalyzer {
    /// Create a YouTube thumbnail analyzer (similar to your existing GeminiService)
    /// - Parameter apiKey: Your Google AI API key
    /// - Returns: Configured GeminiImageAnalyzer for YouTube thumbnail analysis
    public static func youtubeThumbnailAnalyzer(apiKey: String) -> GeminiImageAnalyzer {
        return GeminiImageAnalyzer(apiKey: apiKey)
    }

    /// Get the default YouTube thumbnail analysis configuration
    /// - Returns: Configuration optimized for YouTube thumbnail analysis
    public static func youtubeThumbnailConfiguration() -> ImageAnalysisConfiguration {
        return ImageAnalysisConfiguration(
            prompt: """
            Analyze this YouTube thumbnail and generate a highly accurate AI prompt that only describes the visual style, color palette, mood, composition, lighting, subject appearance, and artistic influences. Do not include or mention any text, title, watermark, symbols, UI elements, or lettering found in the image. Return a single valid JSON object only. JSON keys required: style, colors, subject, lighting, layout, final_prompt.

            For the 'layout' key, explicitly describe the **shot type** (e.g., Extreme Close-up, Wide Shot), **camera angle** (e.g., Low Angle, High Angle), and **depth of field** (e.g., Shallow DoF/Bokeh, Deep DoF)

            Example: {"style":"cinematic realistic","colors":"warm neon palette","subject":"female character with pink hair and futuristic jacket","lighting":"glow neon rim light","layout":"tight close-up portrait composition","final_prompt":"cinematic sci-fi portrait, glowing neon lighting, ultra detailed skin texture, cyberpunk atmosphere, 8k rendering"}
            """,
            temperature: 0.7,
            maxTokens: 1000
        )
    }
}
