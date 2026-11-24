// Bangladesh Administrative Geo Data (8 Divisions, 64 Districts)
// Sourced from Bangladesh GeoJSON / Shapefile dataset

class AdministrativeRegion {
  final String id;
  final String name;
  final String bnName;
  final double lat;
  final double lng;
  final String? divisionId;

  const AdministrativeRegion({
    required this.id,
    required this.name,
    required this.bnName,
    required this.lat,
    required this.lng,
    this.divisionId,
  });
}

class BangladeshAdministrativeData {
  BangladeshAdministrativeData._();

  static const List<AdministrativeRegion> divisions = [
    AdministrativeRegion(
      id: '1',
      name: 'Barishal',
      bnName: 'বরিশাল',
      lat: 22.701002,
      lng: 90.353451,
    ),
    AdministrativeRegion(
      id: '2',
      name: 'Chattogram',
      bnName: 'চট্টগ্রাম',
      lat: 22.356851,
      lng: 91.783182,
    ),
    AdministrativeRegion(
      id: '3',
      name: 'Dhaka',
      bnName: 'ঢাকা',
      lat: 23.810332,
      lng: 90.412518,
    ),
    AdministrativeRegion(
      id: '4',
      name: 'Khulna',
      bnName: 'খুলনা',
      lat: 22.845641,
      lng: 89.540328,
    ),
    AdministrativeRegion(
      id: '5',
      name: 'Rajshahi',
      bnName: 'রাজশাহী',
      lat: 24.363589,
      lng: 88.624135,
    ),
    AdministrativeRegion(
      id: '6',
      name: 'Rangpur',
      bnName: 'রংপুর',
      lat: 25.743892,
      lng: 89.275227,
    ),
    AdministrativeRegion(
      id: '7',
      name: 'Sylhet',
      bnName: 'সিলেট',
      lat: 24.894929,
      lng: 91.868706,
    ),
    AdministrativeRegion(
      id: '8',
      name: 'Mymensingh',
      bnName: 'ময়মনসিংহ',
      lat: 24.747149,
      lng: 90.420273,
    ),
  ];

  static const List<AdministrativeRegion> districts = [
    AdministrativeRegion(
      id: '1',
      divisionId: '3',
      name: 'Dhaka',
      bnName: 'ঢাকা',
      lat: 23.7115253,
      lng: 90.4111451,
    ),
    AdministrativeRegion(
      id: '2',
      divisionId: '3',
      name: 'Faridpur',
      bnName: 'ফরিদপুর',
      lat: 23.6070822,
      lng: 89.8429406,
    ),
    AdministrativeRegion(
      id: '3',
      divisionId: '3',
      name: 'Gazipur',
      bnName: 'গাজীপুর',
      lat: 24.0022858,
      lng: 90.4264283,
    ),
    AdministrativeRegion(
      id: '4',
      divisionId: '3',
      name: 'Gopalganj',
      bnName: 'গোপালগঞ্জ',
      lat: 23.0050857,
      lng: 89.8266059,
    ),
    AdministrativeRegion(
      id: '5',
      divisionId: '8',
      name: 'Jamalpur',
      bnName: 'জামালপুর',
      lat: 24.937533,
      lng: 89.937775,
    ),
    AdministrativeRegion(
      id: '6',
      divisionId: '3',
      name: 'Kishoreganj',
      bnName: 'কিশোরগঞ্জ',
      lat: 24.444937,
      lng: 90.776575,
    ),
    AdministrativeRegion(
      id: '7',
      divisionId: '3',
      name: 'Madaripur',
      bnName: 'মাদারীপুর',
      lat: 23.164102,
      lng: 90.1896805,
    ),
    AdministrativeRegion(
      id: '8',
      divisionId: '3',
      name: 'Manikganj',
      bnName: 'মানিকগঞ্জ',
      lat: 23.8644,
      lng: 90.0047,
    ),
    AdministrativeRegion(
      id: '9',
      divisionId: '3',
      name: 'Munshiganj',
      bnName: 'মুন্সিগঞ্জ',
      lat: 23.5422,
      lng: 90.5305,
    ),
    AdministrativeRegion(
      id: '10',
      divisionId: '8',
      name: 'Mymensingh',
      bnName: 'ময়মনসিংহ',
      lat: 24.7471,
      lng: 90.4203,
    ),
    AdministrativeRegion(
      id: '11',
      divisionId: '3',
      name: 'Narayanganj',
      bnName: 'নারায়ণগঞ্জ',
      lat: 23.63366,
      lng: 90.496482,
    ),
    AdministrativeRegion(
      id: '12',
      divisionId: '3',
      name: 'Narsingdi',
      bnName: 'নরসিংদী',
      lat: 23.932233,
      lng: 90.71541,
    ),
    AdministrativeRegion(
      id: '13',
      divisionId: '8',
      name: 'Netrokona',
      bnName: 'নেত্রকোণা',
      lat: 24.870955,
      lng: 90.727887,
    ),
    AdministrativeRegion(
      id: '14',
      divisionId: '3',
      name: 'Rajbari',
      bnName: 'রাজবাড়ি',
      lat: 23.7574305,
      lng: 89.6444665,
    ),
    AdministrativeRegion(
      id: '15',
      divisionId: '3',
      name: 'Shariatpur',
      bnName: 'শরীয়তপুর',
      lat: 23.2423,
      lng: 90.4348,
    ),
    AdministrativeRegion(
      id: '16',
      divisionId: '8',
      name: 'Sherpur',
      bnName: 'শেরপুর',
      lat: 25.0204933,
      lng: 90.0152966,
    ),
    AdministrativeRegion(
      id: '17',
      divisionId: '3',
      name: 'Tangail',
      bnName: 'টাঙ্গাইল',
      lat: 24.2513,
      lng: 89.9167,
    ),
    AdministrativeRegion(
      id: '18',
      divisionId: '5',
      name: 'Bogura',
      bnName: 'বগুড়া',
      lat: 24.8465228,
      lng: 89.377755,
    ),
    AdministrativeRegion(
      id: '19',
      divisionId: '5',
      name: 'Joypurhat',
      bnName: 'জয়পুরহাট',
      lat: 25.0968,
      lng: 89.0227,
    ),
    AdministrativeRegion(
      id: '20',
      divisionId: '5',
      name: 'Naogaon',
      bnName: 'নওগাঁ',
      lat: 24.7936,
      lng: 88.9318,
    ),
    AdministrativeRegion(
      id: '21',
      divisionId: '5',
      name: 'Natore',
      bnName: 'নাটোর',
      lat: 24.420556,
      lng: 89.000282,
    ),
    AdministrativeRegion(
      id: '22',
      divisionId: '5',
      name: 'Nawabganj',
      bnName: 'নবাবগঞ্জ',
      lat: 24.5965034,
      lng: 88.2775122,
    ),
    AdministrativeRegion(
      id: '23',
      divisionId: '5',
      name: 'Pabna',
      bnName: 'পাবনা',
      lat: 23.998524,
      lng: 89.233645,
    ),
    AdministrativeRegion(
      id: '24',
      divisionId: '5',
      name: 'Rajshahi',
      bnName: 'রাজশাহী',
      lat: 24.3745,
      lng: 88.6042,
    ),
    AdministrativeRegion(
      id: '25',
      divisionId: '5',
      name: 'Sirajgonj',
      bnName: 'সিরাজগঞ্জ',
      lat: 24.4533978,
      lng: 89.7006815,
    ),
    AdministrativeRegion(
      id: '26',
      divisionId: '6',
      name: 'Dinajpur',
      bnName: 'দিনাজপুর',
      lat: 25.6217061,
      lng: 88.6354504,
    ),
    AdministrativeRegion(
      id: '27',
      divisionId: '6',
      name: 'Gaibandha',
      bnName: 'গাইবান্ধা',
      lat: 25.328751,
      lng: 89.528088,
    ),
    AdministrativeRegion(
      id: '28',
      divisionId: '6',
      name: 'Kurigram',
      bnName: 'কুড়িগ্রাম',
      lat: 25.805445,
      lng: 89.636174,
    ),
    AdministrativeRegion(
      id: '29',
      divisionId: '6',
      name: 'Lalmonirhat',
      bnName: 'লালমনিরহাট',
      lat: 25.9923,
      lng: 89.2847,
    ),
    AdministrativeRegion(
      id: '30',
      divisionId: '6',
      name: 'Nilphamari',
      bnName: 'নীলফামারী',
      lat: 25.931794,
      lng: 88.856006,
    ),
    AdministrativeRegion(
      id: '31',
      divisionId: '6',
      name: 'Panchagarh',
      bnName: 'পঞ্চগড়',
      lat: 26.3411,
      lng: 88.5541606,
    ),
    AdministrativeRegion(
      id: '32',
      divisionId: '6',
      name: 'Rangpur',
      bnName: 'রংপুর',
      lat: 25.7558096,
      lng: 89.244462,
    ),
    AdministrativeRegion(
      id: '33',
      divisionId: '6',
      name: 'Thakurgaon',
      bnName: 'ঠাকুরগাঁও',
      lat: 26.0336945,
      lng: 88.4616834,
    ),
    AdministrativeRegion(
      id: '34',
      divisionId: '1',
      name: 'Barguna',
      bnName: 'বরগুনা',
      lat: 22.0953,
      lng: 90.1121,
    ),
    AdministrativeRegion(
      id: '35',
      divisionId: '1',
      name: 'Barishal',
      bnName: 'বরিশাল',
      lat: 22.701,
      lng: 90.3535,
    ),
    AdministrativeRegion(
      id: '36',
      divisionId: '1',
      name: 'Bhola',
      bnName: 'ভোলা',
      lat: 22.685923,
      lng: 90.648179,
    ),
    AdministrativeRegion(
      id: '37',
      divisionId: '1',
      name: 'Jhalokati',
      bnName: 'ঝালকাঠি',
      lat: 22.6406,
      lng: 90.1987,
    ),
    AdministrativeRegion(
      id: '38',
      divisionId: '1',
      name: 'Patuakhali',
      bnName: 'পটুয়াখালী',
      lat: 22.3596316,
      lng: 90.3298712,
    ),
    AdministrativeRegion(
      id: '39',
      divisionId: '1',
      name: 'Pirojpur',
      bnName: 'পিরোজপুর',
      lat: 22.5841,
      lng: 89.972,
    ),
    AdministrativeRegion(
      id: '40',
      divisionId: '2',
      name: 'Bandarban',
      bnName: 'বান্দরবান',
      lat: 22.1953275,
      lng: 92.2183773,
    ),
    AdministrativeRegion(
      id: '41',
      divisionId: '2',
      name: 'Brahmanbaria',
      bnName: 'ব্রাহ্মণবাড়িয়া',
      lat: 23.9570904,
      lng: 91.1119286,
    ),
    AdministrativeRegion(
      id: '42',
      divisionId: '2',
      name: 'Chandpur',
      bnName: 'চাঁদপুর',
      lat: 23.2332585,
      lng: 90.6712912,
    ),
    AdministrativeRegion(
      id: '43',
      divisionId: '2',
      name: 'Chattogram',
      bnName: 'চট্টগ্রাম',
      lat: 22.335109,
      lng: 91.834073,
    ),
    AdministrativeRegion(
      id: '44',
      divisionId: '2',
      name: 'Cumilla',
      bnName: 'কুমিল্লা',
      lat: 23.4682747,
      lng: 91.1788135,
    ),
    AdministrativeRegion(
      id: '45',
      divisionId: '2',
      name: "Cox's Bazar",
      bnName: 'কক্স বাজার',
      lat: 21.4272,
      lng: 92.0058,
    ),
    AdministrativeRegion(
      id: '46',
      divisionId: '2',
      name: 'Feni',
      bnName: 'ফেনী',
      lat: 23.0159,
      lng: 91.3976,
    ),
    AdministrativeRegion(
      id: '47',
      divisionId: '2',
      name: 'Khagrachari',
      bnName: 'খাগড়াছড়ি',
      lat: 23.119285,
      lng: 91.984663,
    ),
    AdministrativeRegion(
      id: '48',
      divisionId: '2',
      name: 'Lakshmipur',
      bnName: 'লক্ষ্মীপুর',
      lat: 22.942477,
      lng: 90.841184,
    ),
    AdministrativeRegion(
      id: '49',
      divisionId: '2',
      name: 'Noakhali',
      bnName: 'নোয়াখালী',
      lat: 22.869563,
      lng: 91.099398,
    ),
    AdministrativeRegion(
      id: '50',
      divisionId: '2',
      name: 'Rangamati',
      bnName: 'রাঙ্গামাটি',
      lat: 22.7324,
      lng: 92.2985,
    ),
    AdministrativeRegion(
      id: '51',
      divisionId: '7',
      name: 'Habiganj',
      bnName: 'হবিগঞ্জ',
      lat: 24.374945,
      lng: 91.41553,
    ),
    AdministrativeRegion(
      id: '52',
      divisionId: '7',
      name: 'Maulvibazar',
      bnName: 'মৌলভীবাজার',
      lat: 24.482934,
      lng: 91.777417,
    ),
    AdministrativeRegion(
      id: '53',
      divisionId: '7',
      name: 'Sunamganj',
      bnName: 'সুনামগঞ্জ',
      lat: 25.0658042,
      lng: 91.3950115,
    ),
    AdministrativeRegion(
      id: '54',
      divisionId: '7',
      name: 'Sylhet',
      bnName: 'সিলেট',
      lat: 24.8897956,
      lng: 91.8697894,
    ),
    AdministrativeRegion(
      id: '55',
      divisionId: '4',
      name: 'Bagerhat',
      bnName: 'বাগেরহাট',
      lat: 22.651568,
      lng: 89.785938,
    ),
    AdministrativeRegion(
      id: '56',
      divisionId: '4',
      name: 'Chuadanga',
      bnName: 'চুয়াডাঙ্গা',
      lat: 23.6401961,
      lng: 88.841841,
    ),
    AdministrativeRegion(
      id: '57',
      divisionId: '4',
      name: 'Jashore',
      bnName: 'যশোর',
      lat: 23.16643,
      lng: 89.2081126,
    ),
    AdministrativeRegion(
      id: '58',
      divisionId: '4',
      name: 'Jhenaidah',
      bnName: 'ঝিনাইদহ',
      lat: 23.5448176,
      lng: 89.1539213,
    ),
    AdministrativeRegion(
      id: '59',
      divisionId: '4',
      name: 'Khulna',
      bnName: 'খুলনা',
      lat: 22.815774,
      lng: 89.568679,
    ),
    AdministrativeRegion(
      id: '60',
      divisionId: '4',
      name: 'Kushtia',
      bnName: 'কুষ্টিয়া',
      lat: 23.901258,
      lng: 89.120482,
    ),
    AdministrativeRegion(
      id: '61',
      divisionId: '4',
      name: 'Magura',
      bnName: 'মাগুরা',
      lat: 23.487337,
      lng: 89.419956,
    ),
    AdministrativeRegion(
      id: '62',
      divisionId: '4',
      name: 'Meherpur',
      bnName: 'মেহেরপুর',
      lat: 23.762213,
      lng: 88.631821,
    ),
    AdministrativeRegion(
      id: '63',
      divisionId: '4',
      name: 'Narail',
      bnName: 'নড়াইল',
      lat: 23.172534,
      lng: 89.512672,
    ),
    AdministrativeRegion(
      id: '64',
      divisionId: '4',
      name: 'Satkhira',
      bnName: 'সাতক্ষীরা',
      lat: 22.7185,
      lng: 89.0705,
    ),
  ];

  static List<AdministrativeRegion> getDistrictsByDivision(String divisionId) {
    return districts.where((d) => d.divisionId == divisionId).toList();
  }

  static AdministrativeRegion? findDivisionById(String id) {
    for (final d in divisions) {
      if (d.id == id) return d;
    }
    return null;
  }

  static AdministrativeRegion? findDistrictById(String id) {
    for (final d in districts) {
      if (d.id == id) return d;
    }
    return null;
  }

  static List<AdministrativeRegion> searchDistricts(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return districts;
    return districts.where((d) =>
      d.name.toLowerCase().contains(q) ||
      d.bnName.contains(q)
    ).toList();
  }
}
  static const List<AdministrativeRegion> subdistricts = [
    AdministrativeRegion(
      id: '20005624',
      divisionId: '3', // Dhaka Division
      name: 'Badda',
      bnName: 'বাড্ডা',
      lat: 23.800517,
      lng: 90.454107,
    ),
    AdministrativeRegion(
      id: '20005625',
      divisionId: '3', // Dhaka Division
      name: 'Biman Bandar',
      bnName: 'বিমানবন্দর',
      lat: 23.834235,
      lng: 90.388558,
    ),
    AdministrativeRegion(
      id: '20005626',
      divisionId: '3', // Dhaka Division
      name: 'Cantonment',
      bnName: 'ক্যান্টনমেন্ট',
      lat: 23.822959,
      lng: 90.38745,
    ),
    AdministrativeRegion(
      id: '20005651',
      divisionId: '3', // Dhaka Division
      name: 'Dakshin Khan',
      bnName: 'দক্ষিণখান',
      lat: 23.860505,
      lng: 90.428995,
    ),
    AdministrativeRegion(
      id: '20005627',
      divisionId: '3', // Dhaka Division
      name: 'Demra',
      bnName: 'ডেমরা',
      lat: 23.727336,
      lng: 90.470822,
    ),
    AdministrativeRegion(
      id: '20005628',
      divisionId: '3', // Dhaka Division
      name: 'Dhamrai',
      bnName: 'ধামরাই',
      lat: 23.956808,
      lng: 90.114764,
    ),
    AdministrativeRegion(
      id: '20005629',
      divisionId: '3', // Dhaka Division
      name: 'Dhanmondi',
      bnName: 'ধানমন্ডি',
      lat: 23.744188,
      lng: 90.376713,
    ),
    AdministrativeRegion(
      id: '20005630',
      divisionId: '3', // Dhaka Division
      name: 'Dohar',
      bnName: 'দোহার',
      lat: 23.618596,
      lng: 90.113524,
    ),
    AdministrativeRegion(
      id: '20005631',
      divisionId: '3', // Dhaka Division
      name: 'Gulshan',
      bnName: 'গুলশান',
      lat: 23.78802,
      lng: 90.415889,
    ),
    AdministrativeRegion(
      id: '20005632',
      divisionId: '3', // Dhaka Division
      name: 'Hazaribagh',
      bnName: 'হাজারীবাগ',
      lat: 23.742585,
      lng: 90.362546,
    ),
    AdministrativeRegion(
      id: '20005633',
      divisionId: '3', // Dhaka Division
      name: 'Kafrul',
      bnName: 'কাফরুল',
      lat: 23.786581,
      lng: 90.382232,
    ),
    AdministrativeRegion(
      id: '20005634',
      divisionId: '3', // Dhaka Division
      name: 'Kamrangirchar',
      bnName: 'কামরাঙ্গীরচর',
      lat: 23.718833,
      lng: 90.371542,
    ),
    AdministrativeRegion(
      id: '20005636',
      divisionId: '3', // Dhaka Division
      name: 'Keraniganj',
      bnName: 'কেরানীগঞ্জ',
      lat: 23.711646,
      lng: 90.327356,
    ),
    AdministrativeRegion(
      id: '20005635',
      divisionId: '3', // Dhaka Division
      name: 'Khilgaon',
      bnName: 'খিলগাঁও',
      lat: 23.758093,
      lng: 90.430166,
    ),
    AdministrativeRegion(
      id: '20005637',
      divisionId: '3', // Dhaka Division
      name: 'Kotwali',
      bnName: 'কোতোয়ালি',
      lat: 23.714054,
      lng: 90.405967,
    ),
    AdministrativeRegion(
      id: '20005638',
      divisionId: '3', // Dhaka Division
      name: 'Lalbagh',
      bnName: 'লালবাগ',
      lat: 23.721837,
      lng: 90.384443,
    ),
    AdministrativeRegion(
      id: '20005639',
      divisionId: '3', // Dhaka Division
      name: 'Mirpur',
      bnName: 'মিরপুর',
      lat: 23.787378,
      lng: 90.354465,
    ),
    AdministrativeRegion(
      id: '20005640',
      divisionId: '3', // Dhaka Division
      name: 'Mohammadpur',
      bnName: 'মোহাম্মদপুর',
      lat: 23.757264,
      lng: 90.347636,
    ),
    AdministrativeRegion(
      id: '20005641',
      divisionId: '3', // Dhaka Division
      name: 'Motijheel',
      bnName: 'মতিঝিল',
      lat: 23.732595,
      lng: 90.420259,
    ),
    AdministrativeRegion(
      id: '20005642',
      divisionId: '3', // Dhaka Division
      name: 'Nawabganj',
      bnName: 'নবাবগঞ্জ',
      lat: 23.665194,
      lng: 90.131679,
    ),
    AdministrativeRegion(
      id: '20005643',
      divisionId: '3', // Dhaka Division
      name: 'Pallabi',
      bnName: 'পল্লবী',
      lat: 23.82791,
      lng: 90.353206,
    ),
    AdministrativeRegion(
      id: '20005644',
      divisionId: '3', // Dhaka Division
      name: 'Ramna',
      bnName: 'রমনা',
      lat: 23.744199,
      lng: 90.402777,
    ),
    AdministrativeRegion(
      id: '20005645',
      divisionId: '3', // Dhaka Division
      name: 'Sabujbagh',
      bnName: 'সবুজবাগ',
      lat: 23.746777,
      lng: 90.452954,
    ),
    AdministrativeRegion(
      id: '20005646',
      divisionId: '3', // Dhaka Division
      name: 'Savar',
      bnName: 'সাভার',
      lat: 23.904426,
      lng: 90.276052,
    ),
    AdministrativeRegion(
      id: '20005647',
      divisionId: '3', // Dhaka Division
      name: 'Shyampur',
      bnName: 'শ্যামপুর',
      lat: 23.691635,
      lng: 90.449329,
    ),
    AdministrativeRegion(
      id: '20005648',
      divisionId: '3', // Dhaka Division
      name: 'Sutrapur',
      bnName: 'সূত্রাপুর',
      lat: 23.704104,
      lng: 90.434956,
    ),
    AdministrativeRegion(
      id: '20005649',
      divisionId: '3', // Dhaka Division
      name: 'Tejgaon',
      bnName: 'তেজগাঁও',
      lat: 23.762708,
      lng: 90.392398,
    ),
    AdministrativeRegion(
      id: '20005653',
      divisionId: '3', // Dhaka Division
      name: 'Turag',
      bnName: 'তুরাগ',
      lat: 23.87401,
      lng: 90.374128,
    ),
    AdministrativeRegion(
      id: '20005652',
      divisionId: '3', // Dhaka Division
      name: 'Uttar Khan',
      bnName: 'উত্তরখান',
      lat: 23.87259,
      lng: 90.442511,
    ),
    AdministrativeRegion(
      id: '20005650',
      divisionId: '3', // Dhaka Division
      name: 'Uttara',
      bnName: 'উত্তরা',
      lat: 23.870127,
      lng: 90.393152,
    ),
  ];

  static List<AdministrativeRegion> searchSubdistricts(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return subdistricts;
    return subdistricts.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.bnName.contains(q)
    ).toList();
  }

}