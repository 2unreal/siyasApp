/// Default initial business configuration seeded for House of SIYA's.
/// Note: All fields must remain editable from Settings by the Owner/Admin.
class BusinessDefaults {
  BusinessDefaults._();

  static const String businessName = "House of SIYA's";
  static const String defaultAppTitle = "House of SIYA's";
  static const String contactPhone = '6385876999';
  static const String whatsappNumber = '6385876999';
  
  static const String streetAddress = '#14, 1st floor, Babu Jagjeevan Ram Street, VTB Guberan Garden';
  static const String area = 'Periapanichery, Gerugambakkam';
  static const String cityWithPincode = 'Chennai 600128';
  static const String fullAddress = '$streetAddress, $area, $cityWithPincode';

  // Default Document & Entity Prefixes (Configurable in Settings)
  static const String prefixCustomer = 'CUS-';
  static const String prefixOrder = 'HS-ORD-';
  static const String prefixInvoice = 'HS-INV-';
  static const String prefixPaymentReceipt = 'HS-REC-';
  static const String prefixRental = 'HS-REN-';
  static const String prefixClass = 'HS-CLS-';
  static const String prefixAlteration = 'HS-ALT-';

  // Brand Default Palette Hex Codes
  static const int primaryWine = 0xFF58111A; // Deep wine / burgundy
  static const int accentGold = 0xFFD4AF37;  // Premium Gold
  static const int neutralIvory = 0xFFFFFDF8; // Ivory
}
