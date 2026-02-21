import '../models/gun_type.dart';

class GunHelpers {
  static String getIcon(GunType gun) {
    switch (gun) {
      case GunType.pistol:
        return '🔫';
      case GunType.pcc:
        return '🏹';
      case GunType.shotgun:
        return '💥';
    }
  }

  static String getLabel(GunType gun) {
    switch (gun) {
      case GunType.pistol:
        return 'Pistol';
      case GunType.pcc:
        return 'PCC';
      case GunType.shotgun:
        return 'Shotgun';
    }
  }

  static String getFullName(GunType gun) {
    return '${getIcon(gun)} ${getLabel(gun)}';
  }
}