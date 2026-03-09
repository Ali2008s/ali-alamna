class TVSessionResponse {
  String sessionId;
  int expiresIn;

  TVSessionResponse({
    this.sessionId = "",
    this.expiresIn=0,
  });

  factory TVSessionResponse.fromJson(Map<String, dynamic> json) {
    return TVSessionResponse(
      sessionId: json['session_id'] is String ? json['session_id'] : "",
      expiresIn: json['expires_in'] is int ? json['expires_in'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'expires_in':expiresIn,
    };
  }
}