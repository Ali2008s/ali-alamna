class BaseResponseModel {
  bool status;
  String message;

  BaseResponseModel({
    this.status = false,
    this.message = "",
  });

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    return BaseResponseModel(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }
}

class ArgumentModel {
  String stringArgument;
  int intArgument;
  List listArgument;

  ArgumentModel({
    this.stringArgument = '',
    this.intArgument = -1,
    this.listArgument = const [],
  });
}
