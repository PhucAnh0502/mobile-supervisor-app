class Validators {
  static String? validateNotEmpty(String? value){
    if(value == null || value.isEmpty){
      return 'This field cannot be empty';
    }
    return null;
  }

  static String? validateEmail(String? value){
    if(value == null || value.isEmpty){
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if(!emailRegex.hasMatch(value)){
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value){
    if(value == null || value.isEmpty){
      return 'Phone number cannot be empty';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if(!phoneRegex.hasMatch(value)){
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateCitizenId(String? value){
    if(value == null || value.isEmpty){
      return 'Citizen ID cannot be empty';
    }
    final idRegex = RegExp(r'^[0-9]{9,12}$');
    if(!idRegex.hasMatch(value)){
      return 'Enter a valid Citizen ID';
    }
    return null;
  }
}
