class LoginModel {
  bool? success;
  String? message;
  Driver? driver;

  LoginModel({this.success, this.message, this.driver});

  LoginModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    driver = json['driver'] != null
        ? new Driver.fromJson(json['driver'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.driver != null) {
      data['driver'] = this.driver!.toJson();
    }
    return data;
  }
}

class Driver {
  int? id;
  String? name;
  String? username;
  String? phone;

  Driver({this.id, this.name, this.username, this.phone});

  Driver.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    username = json['username'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['username'] = this.username;
    data['phone'] = this.phone;
    return data;
  }
}
