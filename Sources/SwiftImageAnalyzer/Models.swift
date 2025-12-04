import Foundation

// MARK: - Image Analysis Result

/// Represents the result of an image analysis operation
public struct ImageAnalysisResult {
    /// The raw text response from the analysis service
    public let rawResponse: String

    /// Parsed analysis data (optional, depends on the analyzer)
    public let parsedData: [String: Any]?

    /// Metadata about the analysis
    public let metadata: AnalysisMetadata

    public init(rawResponse: String, parsedData: [String: Any]? = nil, metadata: AnalysisMetadata) {
        self.rawResponse = rawResponse
        self.parsedData = parsedData
        self.metadata = metadata
    }
}

/// Metadata about the image analysis
public struct AnalysisMetadata {
    /// The MIME type of the analyzed image
    public let mimeType: String

    /// Size of the image data in bytes
    public let imageSize: Int

    /// Timestamp when the analysis was performed
    public let timestamp: Date

    /// Name of the analyzer used
    public let analyzerName: String

    /// Processing time in seconds
    public let processingTime: TimeInterval?

    public init(mimeType: String, imageSize: Int, analyzerName: String, processingTime: TimeInterval? = nil) {
        self.mimeType = mimeType
        self.imageSize = imageSize
        self.timestamp = Date()
        self.analyzerName = analyzerName
        self.processingTime = processingTime
    }
}

// MARK: - Analysis Configuration

/// Configuration for image analysis
public struct ImageAnalysisConfiguration {
    /// The prompt to use for analysis
    public let prompt: String

    /// Maximum tokens for the response (optional)
    public let maxTokens: Int?

    /// Temperature for response generation (0.0 to 1.0)
    public let temperature: Double?

    /// Additional parameters specific to the analyzer
    public let additionalParameters: [String: Any]?

    public init(
        prompt: String,
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        additionalParameters: [String: Any]? = nil
    ) {
        self.prompt = prompt
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.additionalParameters = additionalParameters
    }

    /// Default configuration for general image description
    public static let `default` = ImageAnalysisConfiguration(
        prompt: "Describe this image in detail, including objects, colors, composition, and mood.",
        temperature: 0.7
    )
}

// MARK: - Error Types

/// Errors that can occur during image analysis
public enum ImageAnalysisError: LocalizedError {
    /// Invalid image data
    case invalidImageData

    /// Unsupported image format
    case unsupportedImageFormat(String)

    /// Network error
    case networkError(Error)

    /// API error with status code and message
    case apiError(statusCode: Int, message: String)

    /// Authentication error
    case authenticationError(String)

    /// Parsing error
    case parsingError(String)

    /// Unknown error
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The provided image data is invalid or corrupted."
        case .unsupportedImageFormat(let format):
            return "Unsupported image format: \(format)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Image Input Types

/// Represents different types of image input
public enum ImageInput {
    /// Image data directly
    case data(Data, mimeType: String)

    /// File URL
    case fileURL(URL)

    /// Remote URL (will be downloaded)
    case remoteURL(URL)

    /// Get the MIME type for this input
    public var mimeType: String {
        switch self {
        case .data(_, let mimeType):
            return mimeType
        case .fileURL(let url):
            return ImageAnalyzerUtilities.mimeType(for: url)
        case .remoteURL:
            return "application/octet-stream" // Will be determined after download
        }
    }
}

// MARK: - Utility Functions

struct ImageAnalyzerUtilities {
    /// Get MIME type from file extension
    static func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "bmp":
            return "image/bmp"
        case "tiff", "tif":
            return "image/tiff"
        default:
            return "application/octet-stream"
        }
    }

    /// Load image data from various input types
    static func loadImageData(from input: ImageInput) async throws -> (Data, String) {
        switch input {
        case .data(let data, let mimeType):
            return (data, mimeType)

        case .fileURL(let url):
            let data = try Data(contentsOf: url)
            let mimeType = self.mimeType(for: url)
            return (data, mimeType)

        case .remoteURL(let url):
            let (data, response) = try await URLSession.shared.data(from: url)
            let mimeType = response.mimeType ?? self.mimeType(for: url)
            return (data, mimeType)
        }
    }
}
