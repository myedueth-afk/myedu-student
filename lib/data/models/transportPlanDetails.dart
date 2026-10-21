// Safely converts a dynamic JSON value (int, double, or numeric String) to an
// int, preserving null. API may send e.g. expires_in_days as 23.50138379241898.
int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return double.tryParse(value.toString())?.toInt();
}

class TransportPlanDetails {
  final int? id;
  final int? paymentId;
  final String? duration;
  final String? validFrom;
  final String? validTo;
  final String? totalFee;
  final String? paymentMode;
  final String? planStatus;
  final String? status;
  final PlanRoute? route;
  final PlanShift? shift;
  final PlanPickupStop? pickupStop;
  final PlanVehicle? vehicle;
  final String? estimatedPickupTime;
  final int? vehicleId;
  final int? shiftId;
  final PlanFees? fees;
  final int? expiresInDays;

  TransportPlanDetails({
    this.id,
    this.paymentId,
    this.duration,
    this.validFrom,
    this.validTo,
    this.totalFee,
    this.paymentMode,
    this.planStatus,
    this.status,
    this.route,
    this.shift,
    this.pickupStop,
    this.vehicle,
    this.estimatedPickupTime,
    this.vehicleId,
    this.shiftId,
    this.fees,
    this.expiresInDays,
  });

  factory TransportPlanDetails.fromJson(Map<String, dynamic> json) {
    // Parse validity if provided as a single string
    String? validFromParsed;
    String? validToParsed;

    if (json['validity'] != null && json['validity'] is String) {
      final validityParts = (json['validity'] as String).split(' to ');
      if (validityParts.length == 2) {
        validFromParsed = validityParts[0].trim();
        validToParsed = validityParts[1].trim();
      }
    } else {
      validFromParsed = json['valid_from'];
      validToParsed = json['valid_to'];
    }

    // Parse fees object if provided
    String? durationParsed = json['duration'];
    String? totalFeeParsed = json['total_fee'];
    PlanFees? feesParsed;

    if (json['fees'] != null && json['fees'] is Map) {
      feesParsed = PlanFees.fromJson(Map<String, dynamic>.from(json['fees']));
      // Override duration and totalFee with fees object data if available
      durationParsed = feesParsed.duration ?? durationParsed;
      totalFeeParsed = feesParsed.totalFee ?? totalFeeParsed;
    }

    return TransportPlanDetails(
      id: json['id'],
      paymentId: json['payment_id'],
      duration: durationParsed,
      validFrom: validFromParsed,
      validTo: validToParsed,
      totalFee: totalFeeParsed,
      paymentMode: json['payment_mode'],
      planStatus: json['plan_status'],
      status: json['status'],
      route: json['route'] != null ? PlanRoute.fromJson(json['route']) : null,
      shift: json['shift'] != null ? PlanShift.fromJson(json['shift']) : null,
      // Handle both 'pickup_stop' and 'pickup_point' keys
      pickupStop: (json['pickup_stop'] ?? json['pickup_point']) != null
          ? PlanPickupStop.fromJson(Map<String, dynamic>.from(
              json['pickup_stop'] ?? json['pickup_point']))
          : null,
      vehicle: json['vehicle'] != null
          ? PlanVehicle.fromJson(Map<String, dynamic>.from(json['vehicle']))
          : null,
      estimatedPickupTime: json['estimated_pickup_time'],
      vehicleId: json['vehicle_id'],
      shiftId: json['shift_id'],
      fees: feesParsed,
      expiresInDays: _toIntOrNull(json['expires_in_days']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'duration': duration,
      'valid_from': validFrom,
      'valid_to': validTo,
      'total_fee': totalFee,
      'payment_mode': paymentMode,
      'plan_status': planStatus,
      'status': status,
      'route': route?.toJson(),
      'shift': shift?.toJson(),
      'pickup_stop': pickupStop?.toJson(),
      'vehicle': vehicle?.toJson(),
      'estimated_pickup_time': estimatedPickupTime,
      'vehicle_id': vehicleId,
      'shift_id': shiftId,
      'fees': fees?.toJson(),
      'expires_in_days': expiresInDays,
    };
  }

  // Helper method to format validity period
  String get validityPeriod {
    if (validFrom != null && validTo != null) {
      return '$validFrom - $validTo';
    }
    return 'Not available';
  }

  // Helper method to format shift information
  String get shiftDetails {
    if (shift?.name != null && shift?.timeWindow != null) {
      return '${shift!.name} : ${shift!.timeWindow}';
    } else if (shift?.name != null) {
      return shift!.name!;
    } else if (shift?.timeWindow != null) {
      return shift!.timeWindow!;
    }
    return 'Not specified';
  }

  // Helper method to format pickup time
  String get pickupTimeFormatted {
    if (estimatedPickupTime != null) {
      return '$estimatedPickupTime (Estimated)';
    }
    return 'Not available';
  }

  // Helper method to format payment mode
  String get paymentModeFormatted {
    if (paymentMode != null) {
      return paymentMode!.substring(0, 1).toUpperCase() +
          paymentMode!.substring(1);
    }
    return 'Not specified';
  }

  // Helper method to get route display info (Route name | Vehicle registration)
  String get routeDisplayInfo {
    if (route?.name != null && vehicle?.vehicleRegistration != null) {
      return 'Route : ${route!.name} | ${vehicle!.vehicleRegistration}';
    } else if (route?.name != null) {
      return 'Route : ${route!.name}';
    }
    return 'Route information not available';
  }

  // Helper method to get pickup display info (Pickup stop | Estimated time)
  String get pickupDisplayInfo {
    if (pickupStop?.name != null && estimatedPickupTime != null) {
      return 'Your Pickup : ${pickupStop!.name} | $estimatedPickupTime';
    } else if (pickupStop?.name != null) {
      return 'Your Pickup : ${pickupStop!.name}';
    }
    return 'Pickup information not available';
  }
}

class PlanRoute {
  final int? id;
  final String? name;

  PlanRoute({
    this.id,
    this.name,
  });

  factory PlanRoute.fromJson(Map<String, dynamic> json) {
    return PlanRoute(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class PlanShift {
  final String? name;
  final String? timeWindow;

  PlanShift({
    this.name,
    this.timeWindow,
  });

  factory PlanShift.fromJson(Map<String, dynamic> json) {
    return PlanShift(
      name: json['name'],
      timeWindow: json['time_window'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'time_window': timeWindow,
    };
  }
}

class PlanPickupStop {
  final int? id;
  final String? name;

  PlanPickupStop({
    this.id,
    this.name,
  });

  factory PlanPickupStop.fromJson(Map<String, dynamic> json) {
    return PlanPickupStop(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class PlanFees {
  final int? id;
  final String? duration;
  final String? totalFee;

  PlanFees({
    this.id,
    this.duration,
    this.totalFee,
  });

  factory PlanFees.fromJson(Map<String, dynamic> json) {
    return PlanFees(
      id: json['id'],
      duration: json['duration'],
      totalFee: json['total_fee'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'duration': duration,
      'total_fee': totalFee,
    };
  }
}

class PlanVehicle {
  final int? vehicleId;
  final String? vehicleName;
  final String? vehicleRegistration;

  PlanVehicle({
    this.vehicleId,
    this.vehicleName,
    this.vehicleRegistration,
  });

  factory PlanVehicle.fromJson(Map<String, dynamic> json) {
    return PlanVehicle(
      vehicleId: json['vehicle_id'],
      vehicleName: json['vehicle_name'],
      vehicleRegistration: json['vehicle_registration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'vehicle_registration': vehicleRegistration,
    };
  }
}
