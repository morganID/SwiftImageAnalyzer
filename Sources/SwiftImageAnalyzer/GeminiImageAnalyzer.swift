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

    /// Create a comprehensive image analyzer for detailed visual analysis
    /// - Parameter apiKey: Your Google AI API key
    /// - Returns: Configured GeminiImageAnalyzer for comprehensive image analysis
    public static func comprehensiveImageAnalyzer(apiKey: String) -> GeminiImageAnalyzer {
        return GeminiImageAnalyzer(apiKey: apiKey)
    }

    /// Get the default YouTube thumbnail analysis configuration
    /// - Returns: Configuration optimized for YouTube thumbnail analysis
    public static func youtubeThumbnailConfiguration() -> ImageAnalysisConfiguration {
        return ImageAnalysisConfiguration(
            prompt: """
            Analyze this YouTube thumbnail and generate a highly accurate AI prompt that only describes the visual elements. Do not include or mention any text, title, watermark, symbols, UI elements, or lettering found in the image. Return a single valid JSON object only. JSON keys required: style, colors, subject, lighting, layout, camera_angle, shot_type, subject_pose, expression, depth_of_field, lighting_direction, color_temperature, composition, focus, final_prompt.

            Detailed specifications for each field:

            - **style**: Overall artistic style (cinematic, realistic, cartoon, anime, digital art, etc.)
            - **colors**: Color palette and mood (warm/cool tones, specific colors, saturation level)
            - **subject**: Main subject description (appearance, clothing, distinctive features)
            - **lighting**: General lighting style and quality (dramatic, soft, harsh, natural, studio)
            - **layout**: Overall composition and framing
            - **camera_angle**: Specific camera perspective (eye-level, low-angle, high-angle, Dutch angle, overhead, ground-level)
            - **shot_type**: Framing distance (extreme close-up, close-up, medium shot, wide shot, long shot, establishing shot)
            - **subject_pose**: Body position and posture (standing, sitting, walking, running, dynamic action, relaxed, tense)
            - **expression**: Facial expression and body language (happy, serious, intense, surprised, confident, mysterious)
            - **depth_of_field**: Focus range (shallow DoF with bokeh, deep focus, selective focus, soft focus)
            - **lighting_direction**: Light source position (front lighting, side lighting, back lighting, rim lighting, top lighting)
            - **color_temperature**: Light color quality (warm golden hour, cool blue hour, neutral daylight, tungsten warm)
            - **composition**: Visual balance and arrangement (rule of thirds, centered, symmetrical, asymmetrical, leading lines)
            - **focus**: Sharpness and clarity (pin-sharp, slightly soft, dreamy, motion blur, tilt-shift)

            Example: {"style":"cinematic realistic","colors":"warm neon palette with cool blue accents","subject":"female character with pink hair and futuristic jacket","lighting":"dramatic high contrast","layout":"tight close-up portrait composition","camera_angle":"low-angle","shot_type":"extreme close-up","subject_pose":"confident standing","expression":"intense determined gaze","depth_of_field":"shallow with bokeh background","lighting_direction":"rim lighting from left","color_temperature":"cool blue hour","composition":"rule of thirds with face offset","focus":"pin-sharp on eyes","final_prompt":"cinematic sci-fi portrait, dramatic rim lighting, shallow depth of field, cyberpunk atmosphere, 8k rendering"}
            """,
            temperature: 0.7,
            maxTokens: 1500
        )
    }

    /// Get comprehensive image analysis configuration for detailed visual analysis
    /// - Returns: Configuration for detailed image analysis with all visual aspects
    public static func comprehensiveImageConfiguration() -> ImageAnalysisConfiguration {
        return ImageAnalysisConfiguration(
            prompt: """
            Analyze this image and provide a comprehensive visual description. Return a single valid JSON object only. JSON keys required: style, colors, subject, lighting, layout, camera_angle, shot_type, subject_pose, expression, depth_of_field, lighting_direction, color_temperature, composition, focus, mood, texture_details, final_prompt.

            Detailed specifications for each field:

            - **style**: Overall artistic style and technique (photorealistic, cinematic, digital art, painting, illustration, etc.)
            - **colors**: Complete color analysis (palette, saturation, contrast, dominant colors, color harmony)
            - **subject**: Detailed subject description (appearance, pose, clothing, distinctive features, scale, position)
            - **lighting**: Comprehensive lighting analysis (intensity, quality, shadows, highlights, light sources)
            - **layout**: Overall composition and spatial arrangement
            - **camera_angle**: Precise camera perspective (eye-level, low-angle, high-angle, Dutch angle, overhead, worm's-eye, bird's-eye)
            - **shot_type**: Framing and distance (extreme close-up, close-up, medium shot, wide shot, long shot, establishing shot, aerial)
            - **subject_pose**: Detailed body position and posture (standing erect, leaning, dynamic motion, relaxed pose, gesture)
            - **expression**: Facial expression and body language (facial features, emotional state, body posture, energy level)
            - **depth_of_field**: Focus characteristics (shallow with bokeh, deep focus, selective focus, soft focus, rack focus)
            - **lighting_direction**: Light source positioning (front lighting, side lighting, back lighting, rim lighting, top lighting, bottom lighting)
            - **color_temperature**: Light color quality (warm golden hour, cool blue hour, neutral daylight, tungsten warm, fluorescent cool)
            - **composition**: Visual balance and design principles (rule of thirds, golden ratio, centered, symmetrical, asymmetrical, leading lines, foreground interest)
            - **focus**: Sharpness and clarity details (pin-sharp, slightly soft, dreamy, motion blur, tilt-shift, selective focus, depth cues)
            - **mood**: Emotional atmosphere (dramatic, serene, intense, mysterious, joyful, melancholic, energetic)
            - **texture_details**: Surface qualities and materials (smooth, rough, metallic, fabric, skin texture, environmental details)

            Example: {"style":"cinematic photorealistic","colors":"vibrant warm palette with golden highlights","subject":"young woman with flowing hair in elegant dress","lighting":"soft directional with golden hour warmth","layout":"centered portrait with negative space","camera_angle":"slight low-angle","shot_type":"medium close-up","subject_pose":"graceful standing with gentle lean","expression":"confident and serene","depth_of_field":"shallow with creamy bokeh","lighting_direction":"side lighting from right","color_temperature":"warm golden hour","composition":"rule of thirds with face placement","focus":"sharp on face, soft on background","mood":"elegant and serene","texture_details":"smooth skin, flowing fabric, soft lighting","final_prompt":"cinematic portrait of elegant woman, golden hour lighting, shallow depth of field, photorealistic, 8k resolution"}
            """,
            temperature: 0.7,
            maxTokens: 1800
        )
    }
}
