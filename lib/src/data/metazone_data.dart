// GENERATED FILE — DO NOT EDIT.
//
// Produced by tool/generate_metazone_data.dart from Unicode CLDR 48.
//
// Derived English metazone display names from Unicode CLDR. Licensed
// under Unicode License v3, not the MIT licence of this package's
// source. See LICENSE-CLDR at the package root.
//
// Metazones with no long daylight name (74):
// Afghanistan, Africa_Central, Africa_Eastern, Africa_Southern, Africa_Western, Bhutan, Bolivia, Brunei, Casey, Chamorro, Christmas, Cocos, Davis, DumontDUrville, East_Timor, Ecuador, Europe_Further_Eastern, French_Guiana, French_Southern, GMT, Galapagos, Gambier, Gilbert_Islands, Guam, Gulf, Guyana, Hawaii, India, Indian_Ocean, Indochina, Indonesia_Central, Indonesia_Eastern, Indonesia_Western, Kazakhstan, Kazakhstan_Eastern, Kazakhstan_Western, Kosrae, Kyrgystan, Lanka, Line_Islands, Malaysia, Maldives, Marquesas, Marshall_Islands, Mawson, Myanmar, Nauru, Nepal, Niue, North_Mariana, Palau, Papua_New_Guinea, Phoenix_Islands, Pitcairn, Ponape, Pyongyang, Reunion, Rothera, Seychelles, Singapore, Solomon, South_Georgia, Suriname, Syowa, Tahiti, Tajikistan, Tokelau, Truk, Tuvalu, Venezuela, Vostok, Wake, Wallis, Yukon
//
// Metazone ids referenced by membership history but not localized in en-001
// (31): Africa_FarWestern, Aktyubinsk, Alaska_Hawaii, Ashkhabad, Baku, Bering, Borneo, British, Dacca, Dominican, Dushanbe, Dutch_Guiana, Frunze, Goose_Bay, Greenland_Central, Irish, Karachi, Kizilorda, Kuybyshev, Kwajalein, Liberia, Malaya, Oral, Samarkand, Shevchenko, Sverdlovsk, Tashkent, Tbilisi, Uralsk, Urumqi, Yerevan
library;

/// CLDR release the metazone names in this package come from.
const String cldrVersion = '48';

/// CLDR long names: generic, standard, and daylight.
class MetazoneLongNames {
  const MetazoneLongNames({this.generic, this.standard, this.daylight});

  final String? generic;
  final String? standard;
  final String? daylight;
}

/// Metazone membership interval in UTC milliseconds (half-open).
class MetazoneRange {
  const MetazoneRange({required this.metazoneId, this.fromMs, this.toMs});

  final String metazoneId;

  /// Inclusive start, or null for −∞.
  final int? fromMs;

  /// Exclusive end, or null for +∞.
  final int? toMs;
}

/// IANA id → CLDR zone key when they differ (BCP-47 alias head).
const Map<String, String> ianaToCldrZoneKey = <String, String>{
  "Africa/Asmara": "Africa/Asmera",
  "America/Argentina/Buenos_Aires": "America/Buenos_Aires",
  "America/Argentina/Catamarca": "America/Catamarca",
  "America/Argentina/Cordoba": "America/Cordoba",
  "America/Argentina/Jujuy": "America/Jujuy",
  "America/Argentina/Mendoza": "America/Mendoza",
  "America/Atikokan": "America/Coral_Harbour",
  "America/Indiana/Indianapolis": "America/Indianapolis",
  "America/Kentucky/Louisville": "America/Louisville",
  "America/Nuuk": "America/Godthab",
  "Asia/Ho_Chi_Minh": "Asia/Saigon",
  "Asia/Kathmandu": "Asia/Katmandu",
  "Asia/Kolkata": "Asia/Calcutta",
  "Asia/Yangon": "Asia/Rangoon",
  "Atlantic/Faroe": "Atlantic/Faeroe",
  "Europe/Kyiv": "Europe/Kiev",
  "Pacific/Chuuk": "Pacific/Truk",
  "Pacific/Kanton": "Pacific/Enderbury",
  "Pacific/Pohnpei": "Pacific/Ponape",
};

/// Metazone id → en-001 long names.
const Map<String, MetazoneLongNames> metazoneLongNames =
    <String, MetazoneLongNames>{
      "Acre": MetazoneLongNames(
        generic: "Acre Time",
        standard: "Acre Standard Time",
        daylight: "Acre Summer Time",
      ),
      "Afghanistan": MetazoneLongNames(
        generic: null,
        standard: "Afghanistan Time",
        daylight: null,
      ),
      "Africa_Central": MetazoneLongNames(
        generic: null,
        standard: "Central Africa Time",
        daylight: null,
      ),
      "Africa_Eastern": MetazoneLongNames(
        generic: null,
        standard: "East Africa Time",
        daylight: null,
      ),
      "Africa_Southern": MetazoneLongNames(
        generic: null,
        standard: "South Africa Standard Time",
        daylight: null,
      ),
      "Africa_Western": MetazoneLongNames(
        generic: null,
        standard: "West Africa Time",
        daylight: null,
      ),
      "Alaska": MetazoneLongNames(
        generic: "Alaska Time",
        standard: "Alaska Standard Time",
        daylight: "Alaska Daylight Time",
      ),
      "Almaty": MetazoneLongNames(
        generic: "Almaty Time",
        standard: "Almaty Standard Time",
        daylight: "Almaty Summer Time",
      ),
      "Amazon": MetazoneLongNames(
        generic: "Amazon Time",
        standard: "Amazon Standard Time",
        daylight: "Amazon Summer Time",
      ),
      "America_Central": MetazoneLongNames(
        generic: "Central Time",
        standard: "Central Standard Time",
        daylight: "Central Daylight Time",
      ),
      "America_Eastern": MetazoneLongNames(
        generic: "Eastern Time",
        standard: "Eastern Standard Time",
        daylight: "Eastern Daylight Time",
      ),
      "America_Mountain": MetazoneLongNames(
        generic: "Mountain Time",
        standard: "Mountain Standard Time",
        daylight: "Mountain Daylight Time",
      ),
      "America_Pacific": MetazoneLongNames(
        generic: "Pacific Time",
        standard: "Pacific Standard Time",
        daylight: "Pacific Daylight Time",
      ),
      "Anadyr": MetazoneLongNames(
        generic: "Anadyr Time",
        standard: "Anadyr Standard Time",
        daylight: "Anadyr Summer Time",
      ),
      "Apia": MetazoneLongNames(
        generic: "Samoa Time",
        standard: "Samoa Standard Time",
        daylight: "Samoa Daylight Time",
      ),
      "Aqtau": MetazoneLongNames(
        generic: "Aqtau Time",
        standard: "Aqtau Standard Time",
        daylight: "Aqtau Summer Time",
      ),
      "Aqtobe": MetazoneLongNames(
        generic: "Aqtobe Time",
        standard: "Aqtobe Standard Time",
        daylight: "Aqtobe Summer Time",
      ),
      "Arabian": MetazoneLongNames(
        generic: "Arabian Time",
        standard: "Arabian Standard Time",
        daylight: "Arabian Daylight Time",
      ),
      "Argentina": MetazoneLongNames(
        generic: "Argentina Time",
        standard: "Argentina Standard Time",
        daylight: "Argentina Summer Time",
      ),
      "Argentina_Western": MetazoneLongNames(
        generic: "Western Argentina Time",
        standard: "Western Argentina Standard Time",
        daylight: "Western Argentina Summer Time",
      ),
      "Armenia": MetazoneLongNames(
        generic: "Armenia Time",
        standard: "Armenia Standard Time",
        daylight: "Armenia Summer Time",
      ),
      "Atlantic": MetazoneLongNames(
        generic: "Atlantic Time",
        standard: "Atlantic Standard Time",
        daylight: "Atlantic Daylight Time",
      ),
      "Australia_Central": MetazoneLongNames(
        generic: "Australian Central Time",
        standard: "Australian Central Standard Time",
        daylight: "Australian Central Daylight Time",
      ),
      "Australia_CentralWestern": MetazoneLongNames(
        generic: "Australian Central Western Time",
        standard: "Australian Central Western Standard Time",
        daylight: "Australian Central Western Daylight Time",
      ),
      "Australia_Eastern": MetazoneLongNames(
        generic: "Australian Eastern Time",
        standard: "Australian Eastern Standard Time",
        daylight: "Australian Eastern Daylight Time",
      ),
      "Australia_Western": MetazoneLongNames(
        generic: "Australian Western Time",
        standard: "Australian Western Standard Time",
        daylight: "Australian Western Daylight Time",
      ),
      "Azerbaijan": MetazoneLongNames(
        generic: "Azerbaijan Time",
        standard: "Azerbaijan Standard Time",
        daylight: "Azerbaijan Summer Time",
      ),
      "Azores": MetazoneLongNames(
        generic: "Azores Time",
        standard: "Azores Standard Time",
        daylight: "Azores Summer Time",
      ),
      "Bangladesh": MetazoneLongNames(
        generic: "Bangladesh Time",
        standard: "Bangladesh Standard Time",
        daylight: "Bangladesh Summer Time",
      ),
      "Bhutan": MetazoneLongNames(
        generic: null,
        standard: "Bhutan Time",
        daylight: null,
      ),
      "Bolivia": MetazoneLongNames(
        generic: null,
        standard: "Bolivia Time",
        daylight: null,
      ),
      "Brasilia": MetazoneLongNames(
        generic: "Brasilia Time",
        standard: "Brasilia Standard Time",
        daylight: "Brasilia Summer Time",
      ),
      "Brunei": MetazoneLongNames(
        generic: null,
        standard: "Brunei Time",
        daylight: null,
      ),
      "Cape_Verde": MetazoneLongNames(
        generic: "Cape Verde Time",
        standard: "Cape Verde Standard Time",
        daylight: "Cape Verde Summer Time",
      ),
      "Casey": MetazoneLongNames(
        generic: null,
        standard: "Casey Time",
        daylight: null,
      ),
      "Chamorro": MetazoneLongNames(
        generic: null,
        standard: "Chamorro Standard Time",
        daylight: null,
      ),
      "Chatham": MetazoneLongNames(
        generic: "Chatham Time",
        standard: "Chatham Standard Time",
        daylight: "Chatham Daylight Time",
      ),
      "Chile": MetazoneLongNames(
        generic: "Chile Time",
        standard: "Chile Standard Time",
        daylight: "Chile Summer Time",
      ),
      "China": MetazoneLongNames(
        generic: "China Time",
        standard: "China Standard Time",
        daylight: "China Daylight Time",
      ),
      "Christmas": MetazoneLongNames(
        generic: null,
        standard: "Christmas Island Time",
        daylight: null,
      ),
      "Cocos": MetazoneLongNames(
        generic: null,
        standard: "Cocos Islands Time",
        daylight: null,
      ),
      "Colombia": MetazoneLongNames(
        generic: "Colombia Time",
        standard: "Colombia Standard Time",
        daylight: "Colombia Summer Time",
      ),
      "Cook": MetazoneLongNames(
        generic: "Cook Islands Time",
        standard: "Cook Islands Standard Time",
        daylight: "Cook Islands Summer Time",
      ),
      "Cuba": MetazoneLongNames(
        generic: "Cuba Time",
        standard: "Cuba Standard Time",
        daylight: "Cuba Daylight Time",
      ),
      "Davis": MetazoneLongNames(
        generic: null,
        standard: "Davis Time",
        daylight: null,
      ),
      "DumontDUrville": MetazoneLongNames(
        generic: null,
        standard: "Dumont d’Urville Time",
        daylight: null,
      ),
      "East_Timor": MetazoneLongNames(
        generic: null,
        standard: "Timor-Leste Time",
        daylight: null,
      ),
      "Easter": MetazoneLongNames(
        generic: "Easter Island Time",
        standard: "Easter Island Standard Time",
        daylight: "Easter Island Summer Time",
      ),
      "Ecuador": MetazoneLongNames(
        generic: null,
        standard: "Ecuador Time",
        daylight: null,
      ),
      "Europe_Central": MetazoneLongNames(
        generic: "Central European Time",
        standard: "Central European Standard Time",
        daylight: "Central European Summer Time",
      ),
      "Europe_Eastern": MetazoneLongNames(
        generic: "Eastern European Time",
        standard: "Eastern European Standard Time",
        daylight: "Eastern European Summer Time",
      ),
      "Europe_Further_Eastern": MetazoneLongNames(
        generic: null,
        standard: "Further-eastern European Time",
        daylight: null,
      ),
      "Europe_Western": MetazoneLongNames(
        generic: "Western European Time",
        standard: "Western European Standard Time",
        daylight: "Western European Summer Time",
      ),
      "Falkland": MetazoneLongNames(
        generic: "Falkland Islands Time",
        standard: "Falkland Islands Standard Time",
        daylight: "Falkland Islands Summer Time",
      ),
      "Fiji": MetazoneLongNames(
        generic: "Fiji Time",
        standard: "Fiji Standard Time",
        daylight: "Fiji Summer Time",
      ),
      "French_Guiana": MetazoneLongNames(
        generic: null,
        standard: "French Guiana Time",
        daylight: null,
      ),
      "French_Southern": MetazoneLongNames(
        generic: null,
        standard: "French Southern & Antarctic Time",
        daylight: null,
      ),
      "GMT": MetazoneLongNames(
        generic: null,
        standard: "Greenwich Mean Time",
        daylight: null,
      ),
      "Galapagos": MetazoneLongNames(
        generic: null,
        standard: "Galapagos Time",
        daylight: null,
      ),
      "Gambier": MetazoneLongNames(
        generic: null,
        standard: "Gambier Time",
        daylight: null,
      ),
      "Georgia": MetazoneLongNames(
        generic: "Georgia Time",
        standard: "Georgia Standard Time",
        daylight: "Georgia Summer Time",
      ),
      "Gilbert_Islands": MetazoneLongNames(
        generic: null,
        standard: "Gilbert Islands Time",
        daylight: null,
      ),
      "Greenland": MetazoneLongNames(
        generic: "Greenland Time",
        standard: "Greenland Standard Time",
        daylight: "Greenland Summer Time",
      ),
      "Greenland_Eastern": MetazoneLongNames(
        generic: "East Greenland Time",
        standard: "East Greenland Standard Time",
        daylight: "East Greenland Summer Time",
      ),
      "Greenland_Western": MetazoneLongNames(
        generic: "West Greenland Time",
        standard: "West Greenland Standard Time",
        daylight: "West Greenland Summer Time",
      ),
      "Guam": MetazoneLongNames(
        generic: null,
        standard: "Guam Standard Time",
        daylight: null,
      ),
      "Gulf": MetazoneLongNames(
        generic: null,
        standard: "Gulf Standard Time",
        daylight: null,
      ),
      "Guyana": MetazoneLongNames(
        generic: null,
        standard: "Guyana Time",
        daylight: null,
      ),
      "Hawaii": MetazoneLongNames(
        generic: null,
        standard: "Hawaii-Aleutian Standard Time",
        daylight: null,
      ),
      "Hawaii_Aleutian": MetazoneLongNames(
        generic: "Hawaii-Aleutian Time",
        standard: "Hawaii-Aleutian Standard Time",
        daylight: "Hawaii-Aleutian Daylight Time",
      ),
      "Hong_Kong": MetazoneLongNames(
        generic: "Hong Kong Time",
        standard: "Hong Kong Standard Time",
        daylight: "Hong Kong Summer Time",
      ),
      "Hovd": MetazoneLongNames(
        generic: "Khovd Time",
        standard: "Khovd Standard Time",
        daylight: "Khovd Summer Time",
      ),
      "India": MetazoneLongNames(
        generic: null,
        standard: "India Standard Time",
        daylight: null,
      ),
      "Indian_Ocean": MetazoneLongNames(
        generic: null,
        standard: "Indian Ocean Time",
        daylight: null,
      ),
      "Indochina": MetazoneLongNames(
        generic: null,
        standard: "Indochina Time",
        daylight: null,
      ),
      "Indonesia_Central": MetazoneLongNames(
        generic: null,
        standard: "Central Indonesia Time",
        daylight: null,
      ),
      "Indonesia_Eastern": MetazoneLongNames(
        generic: null,
        standard: "Eastern Indonesia Time",
        daylight: null,
      ),
      "Indonesia_Western": MetazoneLongNames(
        generic: null,
        standard: "Western Indonesia Time",
        daylight: null,
      ),
      "Iran": MetazoneLongNames(
        generic: "Iran Time",
        standard: "Iran Standard Time",
        daylight: "Iran Daylight Time",
      ),
      "Irkutsk": MetazoneLongNames(
        generic: "Irkutsk Time",
        standard: "Irkutsk Standard Time",
        daylight: "Irkutsk Summer Time",
      ),
      "Israel": MetazoneLongNames(
        generic: "Israel Time",
        standard: "Israel Standard Time",
        daylight: "Israel Daylight Time",
      ),
      "Japan": MetazoneLongNames(
        generic: "Japan Time",
        standard: "Japan Standard Time",
        daylight: "Japan Daylight Time",
      ),
      "Kamchatka": MetazoneLongNames(
        generic: "Kamchatka Time",
        standard: "Kamchatka Standard Time",
        daylight: "Kamchatka Summer Time",
      ),
      "Kazakhstan": MetazoneLongNames(
        generic: null,
        standard: "Kazakhstan Time",
        daylight: null,
      ),
      "Kazakhstan_Eastern": MetazoneLongNames(
        generic: null,
        standard: "East Kazakhstan Time",
        daylight: null,
      ),
      "Kazakhstan_Western": MetazoneLongNames(
        generic: null,
        standard: "West Kazakhstan Time",
        daylight: null,
      ),
      "Korea": MetazoneLongNames(
        generic: "Korean Time",
        standard: "Korean Standard Time",
        daylight: "Korean Daylight Time",
      ),
      "Kosrae": MetazoneLongNames(
        generic: null,
        standard: "Kosrae Time",
        daylight: null,
      ),
      "Krasnoyarsk": MetazoneLongNames(
        generic: "Krasnoyarsk Time",
        standard: "Krasnoyarsk Standard Time",
        daylight: "Krasnoyarsk Summer Time",
      ),
      "Kyrgystan": MetazoneLongNames(
        generic: null,
        standard: "Kyrgyzstan Time",
        daylight: null,
      ),
      "Lanka": MetazoneLongNames(
        generic: null,
        standard: "Lanka Time",
        daylight: null,
      ),
      "Line_Islands": MetazoneLongNames(
        generic: null,
        standard: "Line Islands Time",
        daylight: null,
      ),
      "Lord_Howe": MetazoneLongNames(
        generic: "Lord Howe Time",
        standard: "Lord Howe Standard Time",
        daylight: "Lord Howe Daylight Time",
      ),
      "Macau": MetazoneLongNames(
        generic: "Macao Time",
        standard: "Macao Standard Time",
        daylight: "Macao Summer Time",
      ),
      "Magadan": MetazoneLongNames(
        generic: "Magadan Time",
        standard: "Magadan Standard Time",
        daylight: "Magadan Summer Time",
      ),
      "Malaysia": MetazoneLongNames(
        generic: null,
        standard: "Malaysia Time",
        daylight: null,
      ),
      "Maldives": MetazoneLongNames(
        generic: null,
        standard: "Maldives Time",
        daylight: null,
      ),
      "Marquesas": MetazoneLongNames(
        generic: null,
        standard: "Marquesas Time",
        daylight: null,
      ),
      "Marshall_Islands": MetazoneLongNames(
        generic: null,
        standard: "Marshall Islands Time",
        daylight: null,
      ),
      "Mauritius": MetazoneLongNames(
        generic: "Mauritius Time",
        standard: "Mauritius Standard Time",
        daylight: "Mauritius Summer Time",
      ),
      "Mawson": MetazoneLongNames(
        generic: null,
        standard: "Mawson Time",
        daylight: null,
      ),
      "Mexico_Pacific": MetazoneLongNames(
        generic: "Mexican Pacific Time",
        standard: "Mexican Pacific Standard Time",
        daylight: "Mexican Pacific Daylight Time",
      ),
      "Mongolia": MetazoneLongNames(
        generic: "Ulaanbaatar Time",
        standard: "Ulaanbaatar Standard Time",
        daylight: "Ulaanbaatar Summer Time",
      ),
      "Moscow": MetazoneLongNames(
        generic: "Moscow Time",
        standard: "Moscow Standard Time",
        daylight: "Moscow Summer Time",
      ),
      "Myanmar": MetazoneLongNames(
        generic: null,
        standard: "Myanmar Time",
        daylight: null,
      ),
      "Nauru": MetazoneLongNames(
        generic: null,
        standard: "Nauru Time",
        daylight: null,
      ),
      "Nepal": MetazoneLongNames(
        generic: null,
        standard: "Nepal Time",
        daylight: null,
      ),
      "New_Caledonia": MetazoneLongNames(
        generic: "New Caledonia Time",
        standard: "New Caledonia Standard Time",
        daylight: "New Caledonia Summer Time",
      ),
      "New_Zealand": MetazoneLongNames(
        generic: "New Zealand Time",
        standard: "New Zealand Standard Time",
        daylight: "New Zealand Daylight Time",
      ),
      "Newfoundland": MetazoneLongNames(
        generic: "Newfoundland Time",
        standard: "Newfoundland Standard Time",
        daylight: "Newfoundland Daylight Time",
      ),
      "Niue": MetazoneLongNames(
        generic: null,
        standard: "Niue Time",
        daylight: null,
      ),
      "Norfolk": MetazoneLongNames(
        generic: "Norfolk Island Time",
        standard: "Norfolk Island Standard Time",
        daylight: "Norfolk Island Daylight Time",
      ),
      "Noronha": MetazoneLongNames(
        generic: "Fernando de Noronha Time",
        standard: "Fernando de Noronha Standard Time",
        daylight: "Fernando de Noronha Summer Time",
      ),
      "North_Mariana": MetazoneLongNames(
        generic: null,
        standard: "Northern Mariana Islands Time",
        daylight: null,
      ),
      "Novosibirsk": MetazoneLongNames(
        generic: "Novosibirsk Time",
        standard: "Novosibirsk Standard Time",
        daylight: "Novosibirsk Summer Time",
      ),
      "Omsk": MetazoneLongNames(
        generic: "Omsk Time",
        standard: "Omsk Standard Time",
        daylight: "Omsk Summer Time",
      ),
      "Pakistan": MetazoneLongNames(
        generic: "Pakistan Time",
        standard: "Pakistan Standard Time",
        daylight: "Pakistan Summer Time",
      ),
      "Palau": MetazoneLongNames(
        generic: null,
        standard: "Palau Time",
        daylight: null,
      ),
      "Papua_New_Guinea": MetazoneLongNames(
        generic: null,
        standard: "Papua New Guinea Time",
        daylight: null,
      ),
      "Paraguay": MetazoneLongNames(
        generic: "Paraguay Time",
        standard: "Paraguay Standard Time",
        daylight: "Paraguay Summer Time",
      ),
      "Peru": MetazoneLongNames(
        generic: "Peru Time",
        standard: "Peru Standard Time",
        daylight: "Peru Summer Time",
      ),
      "Philippines": MetazoneLongNames(
        generic: "Philippine Time",
        standard: "Philippine Standard Time",
        daylight: "Philippine Summer Time",
      ),
      "Phoenix_Islands": MetazoneLongNames(
        generic: null,
        standard: "Phoenix Islands Time",
        daylight: null,
      ),
      "Pierre_Miquelon": MetazoneLongNames(
        generic: "St Pierre & Miquelon Time",
        standard: "St Pierre & Miquelon Standard Time",
        daylight: "St Pierre & Miquelon Daylight Time",
      ),
      "Pitcairn": MetazoneLongNames(
        generic: null,
        standard: "Pitcairn Time",
        daylight: null,
      ),
      "Ponape": MetazoneLongNames(
        generic: null,
        standard: "Pohnpei Time",
        daylight: null,
      ),
      "Pyongyang": MetazoneLongNames(
        generic: null,
        standard: "North Korea Time",
        daylight: null,
      ),
      "Qyzylorda": MetazoneLongNames(
        generic: "Kyzylorda Time",
        standard: "Kyzylorda Standard Time",
        daylight: "Kyzylorda Summer Time",
      ),
      "Reunion": MetazoneLongNames(
        generic: null,
        standard: "Réunion Time",
        daylight: null,
      ),
      "Rothera": MetazoneLongNames(
        generic: null,
        standard: "Rothera Time",
        daylight: null,
      ),
      "Sakhalin": MetazoneLongNames(
        generic: "Sakhalin Time",
        standard: "Sakhalin Standard Time",
        daylight: "Sakhalin Summer Time",
      ),
      "Samara": MetazoneLongNames(
        generic: "Samara Time",
        standard: "Samara Standard Time",
        daylight: "Samara Summer Time",
      ),
      "Samoa": MetazoneLongNames(
        generic: "American Samoa Time",
        standard: "American Samoa Standard Time",
        daylight: "American Samoa Daylight Time",
      ),
      "Seychelles": MetazoneLongNames(
        generic: null,
        standard: "Seychelles Time",
        daylight: null,
      ),
      "Singapore": MetazoneLongNames(
        generic: null,
        standard: "Singapore Standard Time",
        daylight: null,
      ),
      "Solomon": MetazoneLongNames(
        generic: null,
        standard: "Solomon Islands Time",
        daylight: null,
      ),
      "South_Georgia": MetazoneLongNames(
        generic: null,
        standard: "South Georgia Time",
        daylight: null,
      ),
      "Suriname": MetazoneLongNames(
        generic: null,
        standard: "Suriname Time",
        daylight: null,
      ),
      "Syowa": MetazoneLongNames(
        generic: null,
        standard: "Syowa Time",
        daylight: null,
      ),
      "Tahiti": MetazoneLongNames(
        generic: null,
        standard: "Tahiti Time",
        daylight: null,
      ),
      "Taipei": MetazoneLongNames(
        generic: "Taiwan Time",
        standard: "Taiwan Standard Time",
        daylight: "Taiwan Daylight Time",
      ),
      "Tajikistan": MetazoneLongNames(
        generic: null,
        standard: "Tajikistan Time",
        daylight: null,
      ),
      "Tokelau": MetazoneLongNames(
        generic: null,
        standard: "Tokelau Time",
        daylight: null,
      ),
      "Tonga": MetazoneLongNames(
        generic: "Tonga Time",
        standard: "Tonga Standard Time",
        daylight: "Tonga Summer Time",
      ),
      "Truk": MetazoneLongNames(
        generic: null,
        standard: "Chuuk Time",
        daylight: null,
      ),
      "Turkey": MetazoneLongNames(
        generic: "Türkiye Time",
        standard: "Türkiye Standard Time",
        daylight: "Türkiye Summer Time",
      ),
      "Turkmenistan": MetazoneLongNames(
        generic: "Turkmenistan Time",
        standard: "Turkmenistan Standard Time",
        daylight: "Turkmenistan Summer Time",
      ),
      "Tuvalu": MetazoneLongNames(
        generic: null,
        standard: "Tuvalu Time",
        daylight: null,
      ),
      "Uruguay": MetazoneLongNames(
        generic: "Uruguay Time",
        standard: "Uruguay Standard Time",
        daylight: "Uruguay Summer Time",
      ),
      "Uzbekistan": MetazoneLongNames(
        generic: "Uzbekistan Time",
        standard: "Uzbekistan Standard Time",
        daylight: "Uzbekistan Summer Time",
      ),
      "Vanuatu": MetazoneLongNames(
        generic: "Vanuatu Time",
        standard: "Vanuatu Standard Time",
        daylight: "Vanuatu Summer Time",
      ),
      "Venezuela": MetazoneLongNames(
        generic: null,
        standard: "Venezuela Time",
        daylight: null,
      ),
      "Vladivostok": MetazoneLongNames(
        generic: "Vladivostok Time",
        standard: "Vladivostok Standard Time",
        daylight: "Vladivostok Summer Time",
      ),
      "Volgograd": MetazoneLongNames(
        generic: "Volgograd Time",
        standard: "Volgograd Standard Time",
        daylight: "Volgograd Summer Time",
      ),
      "Vostok": MetazoneLongNames(
        generic: null,
        standard: "Vostok Time",
        daylight: null,
      ),
      "Wake": MetazoneLongNames(
        generic: null,
        standard: "Wake Island Time",
        daylight: null,
      ),
      "Wallis": MetazoneLongNames(
        generic: null,
        standard: "Wallis & Futuna Time",
        daylight: null,
      ),
      "Yakutsk": MetazoneLongNames(
        generic: "Yakutsk Time",
        standard: "Yakutsk Standard Time",
        daylight: "Yakutsk Summer Time",
      ),
      "Yekaterinburg": MetazoneLongNames(
        generic: "Yekaterinburg Time",
        standard: "Yekaterinburg Standard Time",
        daylight: "Yekaterinburg Summer Time",
      ),
      "Yukon": MetazoneLongNames(
        generic: null,
        standard: "Yukon Time",
        daylight: null,
      ),
    };

/// Sparse zone-level en-001 long overrides.
const Map<String, MetazoneLongNames> zoneLongNames =
    <String, MetazoneLongNames>{
      "Etc/UTC": MetazoneLongNames(
        generic: null,
        standard: "Coordinated Universal Time",
        daylight: null,
      ),
      "Europe/Dublin": MetazoneLongNames(
        generic: null,
        standard: null,
        daylight: "Irish Standard Time",
      ),
      "Europe/London": MetazoneLongNames(
        generic: null,
        standard: null,
        daylight: "British Summer Time",
      ),
    };

/// CLDR zone key → metazone membership history (oldest first).
const Map<String, List<MetazoneRange>>
zoneMetazoneHistory = <String, List<MetazoneRange>>{
  "Africa/Abidjan": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Accra": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Addis_Ababa": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Algiers": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: null,
      toMs: 246236400000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 246236400000,
      toMs: 309740400000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: 309740400000,
      toMs: 357523200000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 357523200000,
      toMs: null,
    ),
  ],
  "Africa/Asmera": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Bamako": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Bangui": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Banjul": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Bissau": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Africa_FarWestern",
      fromMs: null,
      toMs: 157770000000,
    ),
    MetazoneRange(metazoneId: "GMT", fromMs: 157770000000, toMs: null),
  ],
  "Africa/Blantyre": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Brazzaville": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Bujumbura": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Cairo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Casablanca": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: null,
      toMs: 448243200000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 448243200000,
      toMs: 504918000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: 504918000000,
      toMs: 1540692000000,
    ),
  ],
  "Africa/Ceuta": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: null,
      toMs: 448243200000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 448243200000,
      toMs: null,
    ),
  ],
  "Africa/Conakry": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Dakar": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Dar_es_Salaam": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Djibouti": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Douala": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/El_Aaiun": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Africa_FarWestern",
      fromMs: null,
      toMs: 198291600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: 198291600000,
      toMs: 1540692000000,
    ),
  ],
  "Africa/Freetown": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Gaborone": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Harare": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Johannesburg": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Southern", fromMs: null, toMs: null),
  ],
  "Africa/Juba": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Africa_Central",
      fromMs: null,
      toMs: 947930400000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Eastern",
      fromMs: 947930400000,
      toMs: 1612126800000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Central",
      fromMs: 1612126800000,
      toMs: null,
    ),
  ],
  "Africa/Kampala": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Khartoum": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Africa_Central",
      fromMs: null,
      toMs: 947930400000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Eastern",
      fromMs: 947930400000,
      toMs: 1509483600000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Central",
      fromMs: 1509483600000,
      toMs: null,
    ),
  ],
  "Africa/Kigali": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Kinshasa": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Lagos": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Libreville": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Lome": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Luanda": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Lubumbashi": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Lusaka": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Malabo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Maputo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Central", fromMs: null, toMs: null),
  ],
  "Africa/Maseru": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Southern", fromMs: null, toMs: null),
  ],
  "Africa/Mbabane": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Southern", fromMs: null, toMs: null),
  ],
  "Africa/Mogadishu": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Monrovia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Liberia", fromMs: null, toMs: 63593100000),
    MetazoneRange(metazoneId: "GMT", fromMs: 63593100000, toMs: null),
  ],
  "Africa/Nairobi": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Africa/Ndjamena": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Niamey": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Nouakchott": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Ouagadougou": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Africa/Porto-Novo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Western", fromMs: null, toMs: null),
  ],
  "Africa/Sao_Tome": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: 1514768400000),
    MetazoneRange(
      metazoneId: "Africa_Western",
      fromMs: 1514768400000,
      toMs: 1546304400000,
    ),
    MetazoneRange(metazoneId: "GMT", fromMs: 1546304400000, toMs: null),
  ],
  "Africa/Tripoli": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: null,
      toMs: 378684000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 378684000000,
      toMs: 641775600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 641775600000,
      toMs: 844034400000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 844034400000,
      toMs: 875916000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 875916000000,
      toMs: 1352505600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 1352505600000,
      toMs: 1382659200000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 1382659200000,
      toMs: null,
    ),
  ],
  "Africa/Tunis": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Africa/Windhoek": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Africa_Southern",
      fromMs: null,
      toMs: 637970400000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Central",
      fromMs: 637970400000,
      toMs: 764200800000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Western",
      fromMs: 764200800000,
      toMs: 1508796000000,
    ),
    MetazoneRange(
      metazoneId: "Africa_Central",
      fromMs: 1508796000000,
      toMs: null,
    ),
  ],
  "America/Adak": <MetazoneRange>[
    MetazoneRange(metazoneId: "Bering", fromMs: null, toMs: 436363200000),
    MetazoneRange(
      metazoneId: "Hawaii_Aleutian",
      fromMs: 439034400000,
      toMs: null,
    ),
  ],
  "America/Anchorage": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Alaska_Hawaii",
      fromMs: null,
      toMs: 436359600000,
    ),
    MetazoneRange(metazoneId: "Alaska", fromMs: 439030800000, toMs: null),
  ],
  "America/Anguilla": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Antigua": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Araguaina": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Argentina/La_Rioja": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 667792800000),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 667792800000,
      toMs: 673588800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 673588800000,
      toMs: 1086058800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1086058800000,
      toMs: 1087704000000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1087704000000, toMs: null),
  ],
  "America/Argentina/Rio_Gallegos": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 1086058800000),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1086058800000,
      toMs: 1087704000000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1087704000000, toMs: null),
  ],
  "America/Argentina/Salta": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 667965600000),
    MetazoneRange(metazoneId: "Argentina", fromMs: 687931200000, toMs: null),
  ],
  "America/Argentina/San_Juan": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 667792800000),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 667792800000,
      toMs: 673588800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 673588800000,
      toMs: 1085972400000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1085972400000,
      toMs: 1090728000000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1090728000000, toMs: null),
  ],
  "America/Argentina/San_Luis": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 637380000000),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 637380000000,
      toMs: 675748800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 675748800000,
      toMs: 938919600000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 938919600000,
      toMs: 952052400000,
    ),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 952052400000,
      toMs: 1085972400000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1085972400000,
      toMs: 1090728000000,
    ),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 1090728000000,
      toMs: 1200880800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1200880800000,
      toMs: 1255233600000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1255233600000, toMs: null),
  ],
  "America/Argentina/Tucuman": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 667965600000),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 687931200000,
      toMs: 1086058800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1086058800000,
      toMs: 1087099200000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1087099200000, toMs: null),
  ],
  "America/Argentina/Ushuaia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 1085886000000),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1087704000000, toMs: null),
  ],
  "America/Aruba": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Asuncion": <MetazoneRange>[
    MetazoneRange(metazoneId: "Paraguay", fromMs: null, toMs: null),
  ],
  "America/Bahia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Bahia_Banderas": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: null,
      toMs: 1270371600000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1270371600000,
      toMs: null,
    ),
  ],
  "America/Barbados": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Belem": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Belize": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Blanc-Sablon": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Boa_Vista": <MetazoneRange>[
    MetazoneRange(metazoneId: "Amazon", fromMs: null, toMs: null),
  ],
  "America/Bogota": <MetazoneRange>[
    MetazoneRange(metazoneId: "Colombia", fromMs: null, toMs: null),
  ],
  "America/Boise": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Mountain", fromMs: null, toMs: null),
  ],
  "America/Buenos_Aires": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: null),
  ],
  "America/Cambridge_Bay": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: null,
      toMs: 941356800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 941356800000,
      toMs: 972802800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 972802800000,
      toMs: 973400400000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 973400400000,
      toMs: 986115600000,
    ),
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: 986115600000,
      toMs: null,
    ),
  ],
  "America/Campo_Grande": <MetazoneRange>[
    MetazoneRange(metazoneId: "Amazon", fromMs: null, toMs: null),
  ],
  "America/Cancun": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 378201600000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 378201600000,
      toMs: 410504400000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 410504400000,
      toMs: 877849200000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 877849200000,
      toMs: 902037600000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 902037600000,
      toMs: 1422777600000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 1422777600000,
      toMs: null,
    ),
  ],
  "America/Caracas": <MetazoneRange>[
    MetazoneRange(metazoneId: "Venezuela", fromMs: null, toMs: null),
  ],
  "America/Catamarca": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 667965600000),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 687931200000,
      toMs: 1086058800000,
    ),
    MetazoneRange(
      metazoneId: "Argentina_Western",
      fromMs: 1086058800000,
      toMs: 1087704000000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1087704000000, toMs: null),
  ],
  "America/Cayenne": <MetazoneRange>[
    MetazoneRange(metazoneId: "French_Guiana", fromMs: null, toMs: null),
  ],
  "America/Cayman": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Chicago": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Chihuahua": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 891766800000,
    ),
    MetazoneRange(
      metazoneId: "Mexico_Pacific",
      fromMs: 891766800000,
      toMs: 1667116800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1667116800000,
      toMs: null,
    ),
  ],
  "America/Ciudad_Juarez": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 891766800000,
    ),
    MetazoneRange(
      metazoneId: "Mexico_Pacific",
      fromMs: 891766800000,
      toMs: 1667116800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1667116800000,
      toMs: 1669788000000,
    ),
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: 1669788000000,
      toMs: null,
    ),
  ],
  "America/Coral_Harbour": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Cordoba": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 667965600000),
    MetazoneRange(metazoneId: "Argentina", fromMs: 687931200000, toMs: null),
  ],
  "America/Costa_Rica": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Coyhaique": <MetazoneRange>[
    MetazoneRange(metazoneId: "Chile", fromMs: null, toMs: 1742439600000),
  ],
  "America/Creston": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Mountain", fromMs: null, toMs: null),
  ],
  "America/Cuiaba": <MetazoneRange>[
    MetazoneRange(metazoneId: "Amazon", fromMs: null, toMs: null),
  ],
  "America/Curacao": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Danmarkshavn": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Greenland_Western",
      fromMs: null,
      toMs: 820465200000,
    ),
    MetazoneRange(metazoneId: "GMT", fromMs: 820465200000, toMs: null),
  ],
  "America/Dawson": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: 120646800000,
      toMs: 1604214000000,
    ),
    MetazoneRange(metazoneId: "Yukon", fromMs: 1604214000000, toMs: null),
  ],
  "America/Dawson_Creek": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 84013200000,
    ),
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: 84013200000,
      toMs: null,
    ),
  ],
  "America/Denver": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Mountain", fromMs: null, toMs: null),
  ],
  "America/Detroit": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Dominica": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Edmonton": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Mountain", fromMs: null, toMs: null),
  ],
  "America/Eirunepe": <MetazoneRange>[
    MetazoneRange(metazoneId: "Acre", fromMs: null, toMs: 1214283600000),
    MetazoneRange(
      metazoneId: "Amazon",
      fromMs: 1214283600000,
      toMs: 1384056000000,
    ),
    MetazoneRange(metazoneId: "Acre", fromMs: 1384056000000, toMs: null),
  ],
  "America/El_Salvador": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Fort_Nelson": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 1425808800000,
    ),
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: 1425808800000,
      toMs: null,
    ),
  ],
  "America/Fortaleza": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Glace_Bay": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Godthab": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Greenland_Western",
      fromMs: null,
      toMs: 1711414800000,
    ),
    MetazoneRange(metazoneId: "Greenland", fromMs: 1711414800000, toMs: null),
  ],
  "America/Goose_Bay": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: 576043260000),
    MetazoneRange(
      metazoneId: "Goose_Bay",
      fromMs: 576043260000,
      toMs: 594180060000,
    ),
    MetazoneRange(metazoneId: "Atlantic", fromMs: 594180060000, toMs: null),
  ],
  "America/Grand_Turk": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 1425798000000,
    ),
    MetazoneRange(
      metazoneId: "Atlantic",
      fromMs: 1425798000000,
      toMs: 1520751600000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 1520751600000,
      toMs: null,
    ),
  ],
  "America/Grenada": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Guadeloupe": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Guatemala": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Guayaquil": <MetazoneRange>[
    MetazoneRange(metazoneId: "Ecuador", fromMs: null, toMs: null),
  ],
  "America/Guyana": <MetazoneRange>[
    MetazoneRange(metazoneId: "Guyana", fromMs: null, toMs: null),
  ],
  "America/Halifax": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Havana": <MetazoneRange>[
    MetazoneRange(metazoneId: "Cuba", fromMs: null, toMs: null),
  ],
  "America/Hermosillo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Mexico_Pacific", fromMs: null, toMs: null),
  ],
  "America/Indiana/Knox": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 688546800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 688546800000,
      toMs: 1143961200000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1143961200000,
      toMs: null,
    ),
  ],
  "America/Indiana/Marengo": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 126687600000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 126687600000,
      toMs: 152089200000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 152089200000,
      toMs: null,
    ),
  ],
  "America/Indiana/Petersburg": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 247042800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 247042800000,
      toMs: 1143961200000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1143961200000,
      toMs: 1194159600000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 1194159600000,
      toMs: null,
    ),
  ],
  "America/Indiana/Tell_City": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 1143961200000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1143961200000,
      toMs: null,
    ),
  ],
  "America/Indiana/Vevay": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Indiana/Vincennes": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 1143961200000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1143961200000,
      toMs: 1194159600000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 1194159600000,
      toMs: null,
    ),
  ],
  "America/Indiana/Winamac": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 1143961200000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1143961200000,
      toMs: 1173600000000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 1173600000000,
      toMs: null,
    ),
  ],
  "America/Indianapolis": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Inuvik": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 294228000000,
    ),
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: 294228000000,
      toMs: null,
    ),
  ],
  "America/Iqaluit": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 941349600000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 941349600000,
      toMs: 972802800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 972802800000,
      toMs: null,
    ),
  ],
  "America/Jamaica": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Jujuy": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 636516000000),
    MetazoneRange(metazoneId: "Argentina", fromMs: 686721600000, toMs: null),
  ],
  "America/Juneau": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 325677600000,
    ),
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: 341402400000,
      toMs: 436352400000,
    ),
    MetazoneRange(metazoneId: "Alaska", fromMs: 439030800000, toMs: null),
  ],
  "America/Kentucky/Monticello": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 972802800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 972802800000,
      toMs: null,
    ),
  ],
  "America/Kralendijk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/La_Paz": <MetazoneRange>[
    MetazoneRange(metazoneId: "Bolivia", fromMs: null, toMs: null),
  ],
  "America/Lima": <MetazoneRange>[
    MetazoneRange(metazoneId: "Peru", fromMs: null, toMs: null),
  ],
  "America/Los_Angeles": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Pacific", fromMs: null, toMs: null),
  ],
  "America/Louisville": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 126687600000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 126687600000,
      toMs: 152089200000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 152089200000,
      toMs: null,
    ),
  ],
  "America/Lower_Princes": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Maceio": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Managua": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 105084000000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 105084000000,
      toMs: 161758800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 161758800000,
      toMs: 694260000000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 694260000000,
      toMs: 717310800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 717310800000,
      toMs: 725868000000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 725868000000,
      toMs: 852094800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 852094800000,
      toMs: null,
    ),
  ],
  "America/Manaus": <MetazoneRange>[
    MetazoneRange(metazoneId: "Amazon", fromMs: null, toMs: null),
  ],
  "America/Marigot": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Martinique": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Matamoros": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Mazatlan": <MetazoneRange>[
    MetazoneRange(metazoneId: "Mexico_Pacific", fromMs: null, toMs: null),
  ],
  "America/Mendoza": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 636516000000),
    MetazoneRange(
      metazoneId: "Argentina",
      fromMs: 719380800000,
      toMs: 1085281200000,
    ),
    MetazoneRange(metazoneId: "Argentina", fromMs: 1096171200000, toMs: null),
  ],
  "America/Menominee": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: null,
      toMs: 104914800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 104914800000,
      toMs: null,
    ),
  ],
  "America/Merida": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 378201600000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 378201600000,
      toMs: 405068400000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 405068400000,
      toMs: null,
    ),
  ],
  "America/Metlakatla": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 1446372000000,
    ),
    MetazoneRange(
      metazoneId: "Alaska",
      fromMs: 1446372000000,
      toMs: 1541325600000,
    ),
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: 1541325600000,
      toMs: 1547978400000,
    ),
    MetazoneRange(metazoneId: "Alaska", fromMs: 1547978400000, toMs: null),
  ],
  "America/Mexico_City": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Miquelon": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: 326001600000),
    MetazoneRange(
      metazoneId: "Pierre_Miquelon",
      fromMs: 326001600000,
      toMs: null,
    ),
  ],
  "America/Moncton": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Monterrey": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Montevideo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Uruguay", fromMs: null, toMs: null),
  ],
  "America/Montserrat": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Nassau": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/New_York": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Nome": <MetazoneRange>[
    MetazoneRange(metazoneId: "Bering", fromMs: null, toMs: 436363200000),
    MetazoneRange(metazoneId: "Alaska", fromMs: 439030800000, toMs: null),
  ],
  "America/Noronha": <MetazoneRange>[
    MetazoneRange(metazoneId: "Noronha", fromMs: null, toMs: null),
  ],
  "America/North_Dakota/Beulah": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: null,
      toMs: 1289116800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1289116800000,
      toMs: null,
    ),
  ],
  "America/North_Dakota/Center": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: null,
      toMs: 720000000000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 720000000000,
      toMs: null,
    ),
  ],
  "America/North_Dakota/New_Salem": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: null,
      toMs: 1067155200000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1067155200000,
      toMs: null,
    ),
  ],
  "America/Ojinaga": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 891766800000,
    ),
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: 891766800000,
      toMs: 1667116800000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1667116800000,
      toMs: null,
    ),
  ],
  "America/Panama": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Paramaribo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Dutch_Guiana", fromMs: null, toMs: 185686200000),
    MetazoneRange(metazoneId: "Suriname", fromMs: 185686200000, toMs: null),
  ],
  "America/Phoenix": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Mountain", fromMs: null, toMs: null),
  ],
  "America/Port-au-Prince": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Port_of_Spain": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Porto_Velho": <MetazoneRange>[
    MetazoneRange(metazoneId: "Amazon", fromMs: null, toMs: null),
  ],
  "America/Puerto_Rico": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Punta_Arenas": <MetazoneRange>[
    MetazoneRange(metazoneId: "Chile", fromMs: null, toMs: 1480806000000),
  ],
  "America/Rankin_Inlet": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 972802800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 972802800000,
      toMs: 986112000000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 986112000000,
      toMs: null,
    ),
  ],
  "America/Recife": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Regina": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Resolute": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: null,
      toMs: 972802800000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 972802800000,
      toMs: 986112000000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 986112000000,
      toMs: 1162105200000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 1162105200000,
      toMs: 1173600000000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 1173600000000,
      toMs: null,
    ),
  ],
  "America/Rio_Branco": <MetazoneRange>[
    MetazoneRange(metazoneId: "Acre", fromMs: null, toMs: 1214283600000),
    MetazoneRange(
      metazoneId: "Amazon",
      fromMs: 1214283600000,
      toMs: 1384056000000,
    ),
    MetazoneRange(metazoneId: "Acre", fromMs: 1384056000000, toMs: null),
  ],
  "America/Santarem": <MetazoneRange>[
    MetazoneRange(metazoneId: "Amazon", fromMs: null, toMs: 1214280000000),
    MetazoneRange(metazoneId: "Brasilia", fromMs: 1214280000000, toMs: null),
  ],
  "America/Santiago": <MetazoneRange>[
    MetazoneRange(metazoneId: "Chile", fromMs: null, toMs: null),
  ],
  "America/Santo_Domingo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Dominican", fromMs: null, toMs: 152082000000),
    MetazoneRange(
      metazoneId: "Atlantic",
      fromMs: 152082000000,
      toMs: 972799200000,
    ),
    MetazoneRange(
      metazoneId: "America_Eastern",
      fromMs: 972799200000,
      toMs: 975823200000,
    ),
    MetazoneRange(metazoneId: "Atlantic", fromMs: 975823200000, toMs: null),
  ],
  "America/Sao_Paulo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brasilia", fromMs: null, toMs: null),
  ],
  "America/Scoresbysund": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Greenland_Central",
      fromMs: null,
      toMs: 354679200000,
    ),
    MetazoneRange(
      metazoneId: "Greenland_Eastern",
      fromMs: 354679200000,
      toMs: 1711846800000,
    ),
    MetazoneRange(metazoneId: "Greenland", fromMs: 1711846800000, toMs: null),
  ],
  "America/Sitka": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 436352400000,
    ),
    MetazoneRange(metazoneId: "Alaska", fromMs: 439030800000, toMs: null),
  ],
  "America/St_Barthelemy": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/St_Johns": <MetazoneRange>[
    MetazoneRange(metazoneId: "Newfoundland", fromMs: null, toMs: null),
  ],
  "America/St_Kitts": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/St_Lucia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/St_Thomas": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/St_Vincent": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Swift_Current": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Mountain",
      fromMs: null,
      toMs: 73472400000,
    ),
    MetazoneRange(
      metazoneId: "America_Central",
      fromMs: 73472400000,
      toMs: null,
    ),
  ],
  "America/Tegucigalpa": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Thule": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Tijuana": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Pacific", fromMs: null, toMs: null),
  ],
  "America/Toronto": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Eastern", fromMs: null, toMs: null),
  ],
  "America/Tortola": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "America/Vancouver": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Pacific", fromMs: null, toMs: null),
  ],
  "America/Whitehorse": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "America_Pacific",
      fromMs: null,
      toMs: 1604214000000,
    ),
    MetazoneRange(metazoneId: "Yukon", fromMs: 1604214000000, toMs: null),
  ],
  "America/Winnipeg": <MetazoneRange>[
    MetazoneRange(metazoneId: "America_Central", fromMs: null, toMs: null),
  ],
  "America/Yakutat": <MetazoneRange>[
    MetazoneRange(metazoneId: "Alaska", fromMs: 439030800000, toMs: null),
  ],
  "Antarctica/Casey": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: null,
      toMs: 1255802400000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1255802400000,
      toMs: 1267714800000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1267714800000,
      toMs: 1319738400000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1319738400000,
      toMs: 1329843600000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1329843600000,
      toMs: 1477065600000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1477065600000,
      toMs: 1520701200000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1520701200000,
      toMs: 1538856000000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1538856000000,
      toMs: 1552752000000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1552752000000,
      toMs: 1570129200000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1570129200000,
      toMs: 1583596800000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1583596800000,
      toMs: 1601740860000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1601740860000,
      toMs: 1615640400000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1615640400000,
      toMs: 1633190460000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1633190460000,
      toMs: 1647090000000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1647090000000,
      toMs: 1664640060000,
    ),
    MetazoneRange(
      metazoneId: "Casey",
      fromMs: 1664640060000,
      toMs: 1678291200000,
    ),
    MetazoneRange(
      metazoneId: "Australia_Western",
      fromMs: 1678291200000,
      toMs: null,
    ),
  ],
  "Antarctica/Davis": <MetazoneRange>[
    MetazoneRange(metazoneId: "Davis", fromMs: null, toMs: null),
  ],
  "Antarctica/DumontDUrville": <MetazoneRange>[
    MetazoneRange(metazoneId: "DumontDUrville", fromMs: null, toMs: null),
  ],
  "Antarctica/Macquarie": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Eastern", fromMs: null, toMs: null),
  ],
  "Antarctica/Mawson": <MetazoneRange>[
    MetazoneRange(metazoneId: "Mawson", fromMs: null, toMs: null),
  ],
  "Antarctica/McMurdo": <MetazoneRange>[
    MetazoneRange(metazoneId: "New_Zealand", fromMs: null, toMs: null),
  ],
  "Antarctica/Palmer": <MetazoneRange>[
    MetazoneRange(metazoneId: "Argentina", fromMs: null, toMs: 389070000000),
    MetazoneRange(
      metazoneId: "Chile",
      fromMs: 389070000000,
      toMs: 1480820400000,
    ),
  ],
  "Antarctica/Rothera": <MetazoneRange>[
    MetazoneRange(metazoneId: "Rothera", fromMs: null, toMs: null),
  ],
  "Antarctica/Syowa": <MetazoneRange>[
    MetazoneRange(metazoneId: "Syowa", fromMs: null, toMs: null),
  ],
  "Antarctica/Troll": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Antarctica/Vostok": <MetazoneRange>[
    MetazoneRange(metazoneId: "Vostok", fromMs: null, toMs: null),
  ],
  "Arctic/Longyearbyen": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Asia/Aden": <MetazoneRange>[
    MetazoneRange(metazoneId: "Arabian", fromMs: null, toMs: null),
  ],
  "Asia/Almaty": <MetazoneRange>[
    MetazoneRange(metazoneId: "Almaty", fromMs: null, toMs: 1099166400000),
    MetazoneRange(
      metazoneId: "Kazakhstan_Eastern",
      fromMs: 1099166400000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Amman": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: null,
      toMs: 1666908000000,
    ),
  ],
  "Asia/Anadyr": <MetazoneRange>[
    MetazoneRange(metazoneId: "Anadyr", fromMs: null, toMs: 1269698400000),
    MetazoneRange(
      metazoneId: "Magadan",
      fromMs: 1269698400000,
      toMs: 1301151600000,
    ),
    MetazoneRange(metazoneId: "Kamchatka", fromMs: 1301151600000, toMs: null),
  ],
  "Asia/Aqtau": <MetazoneRange>[
    MetazoneRange(metazoneId: "Shevchenko", fromMs: null, toMs: 692823600000),
    MetazoneRange(
      metazoneId: "Aqtau",
      fromMs: 692823600000,
      toMs: 1099173600000,
    ),
    MetazoneRange(
      metazoneId: "Kazakhstan_Western",
      fromMs: 1099173600000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Aqtobe": <MetazoneRange>[
    MetazoneRange(metazoneId: "Aktyubinsk", fromMs: null, toMs: 692823600000),
    MetazoneRange(
      metazoneId: "Aqtobe",
      fromMs: 692823600000,
      toMs: 1099170000000,
    ),
    MetazoneRange(
      metazoneId: "Kazakhstan_Western",
      fromMs: 1099170000000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Ashgabat": <MetazoneRange>[
    MetazoneRange(metazoneId: "Ashkhabad", fromMs: null, toMs: 695772000000),
    MetazoneRange(metazoneId: "Turkmenistan", fromMs: 695772000000, toMs: null),
  ],
  "Asia/Atyrau": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Kazakhstan_Western",
      fromMs: 1099173600000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Baghdad": <MetazoneRange>[
    MetazoneRange(metazoneId: "Arabian", fromMs: null, toMs: null),
  ],
  "Asia/Bahrain": <MetazoneRange>[
    MetazoneRange(metazoneId: "Gulf", fromMs: null, toMs: 76190400000),
    MetazoneRange(metazoneId: "Arabian", fromMs: 76190400000, toMs: null),
  ],
  "Asia/Baku": <MetazoneRange>[
    MetazoneRange(metazoneId: "Baku", fromMs: null, toMs: 670370400000),
    MetazoneRange(metazoneId: "Azerbaijan", fromMs: 670370400000, toMs: null),
  ],
  "Asia/Bangkok": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indochina", fromMs: null, toMs: null),
  ],
  "Asia/Barnaul": <MetazoneRange>[
    MetazoneRange(metazoneId: "Krasnoyarsk", fromMs: 1459022400000, toMs: null),
  ],
  "Asia/Beirut": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Asia/Bishkek": <MetazoneRange>[
    MetazoneRange(metazoneId: "Frunze", fromMs: null, toMs: 670363200000),
    MetazoneRange(metazoneId: "Kyrgystan", fromMs: 670363200000, toMs: null),
  ],
  "Asia/Brunei": <MetazoneRange>[
    MetazoneRange(metazoneId: "Brunei", fromMs: null, toMs: null),
  ],
  "Asia/Calcutta": <MetazoneRange>[
    MetazoneRange(metazoneId: "India", fromMs: null, toMs: null),
  ],
  "Asia/Chita": <MetazoneRange>[
    MetazoneRange(metazoneId: "Yakutsk", fromMs: null, toMs: 1414252800000),
    MetazoneRange(
      metazoneId: "Irkutsk",
      fromMs: 1414256400000,
      toMs: 1459015200000,
    ),
    MetazoneRange(metazoneId: "Yakutsk", fromMs: 1459015200000, toMs: null),
  ],
  "Asia/Colombo": <MetazoneRange>[
    MetazoneRange(metazoneId: "India", fromMs: null, toMs: 832962600000),
    MetazoneRange(
      metazoneId: "Lanka",
      fromMs: 832962600000,
      toMs: 1145039400000,
    ),
    MetazoneRange(metazoneId: "India", fromMs: 1145039400000, toMs: null),
  ],
  "Asia/Damascus": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: null,
      toMs: 1666904400000,
    ),
  ],
  "Asia/Dhaka": <MetazoneRange>[
    MetazoneRange(metazoneId: "Dacca", fromMs: null, toMs: 38772000000),
    MetazoneRange(metazoneId: "Bangladesh", fromMs: 38772000000, toMs: null),
  ],
  "Asia/Dili": <MetazoneRange>[
    MetazoneRange(metazoneId: "East_Timor", fromMs: null, toMs: 199897200000),
    MetazoneRange(
      metazoneId: "Indonesia_Central",
      fromMs: 199897200000,
      toMs: 969120000000,
    ),
    MetazoneRange(metazoneId: "East_Timor", fromMs: 969120000000, toMs: null),
  ],
  "Asia/Dubai": <MetazoneRange>[
    MetazoneRange(metazoneId: "Gulf", fromMs: null, toMs: null),
  ],
  "Asia/Dushanbe": <MetazoneRange>[
    MetazoneRange(metazoneId: "Dushanbe", fromMs: null, toMs: 684363600000),
    MetazoneRange(metazoneId: "Tajikistan", fromMs: 684363600000, toMs: null),
  ],
  "Asia/Famagusta": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: null,
      toMs: 1473282000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 1509238800000,
      toMs: null,
    ),
  ],
  "Asia/Gaza": <MetazoneRange>[
    MetazoneRange(metazoneId: "Israel", fromMs: null, toMs: 820447200000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 820447200000,
      toMs: null,
    ),
  ],
  "Asia/Hebron": <MetazoneRange>[
    MetazoneRange(metazoneId: "Israel", fromMs: null, toMs: 820447200000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 820447200000,
      toMs: null,
    ),
  ],
  "Asia/Hong_Kong": <MetazoneRange>[
    MetazoneRange(metazoneId: "Hong_Kong", fromMs: null, toMs: null),
  ],
  "Asia/Hovd": <MetazoneRange>[
    MetazoneRange(metazoneId: "Hovd", fromMs: null, toMs: null),
  ],
  "Asia/Irkutsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Irkutsk", fromMs: null, toMs: null),
  ],
  "Asia/Jakarta": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indonesia_Western", fromMs: null, toMs: null),
  ],
  "Asia/Jayapura": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indonesia_Eastern", fromMs: null, toMs: null),
  ],
  "Asia/Jerusalem": <MetazoneRange>[
    MetazoneRange(metazoneId: "Israel", fromMs: null, toMs: null),
  ],
  "Asia/Kabul": <MetazoneRange>[
    MetazoneRange(metazoneId: "Afghanistan", fromMs: null, toMs: null),
  ],
  "Asia/Kamchatka": <MetazoneRange>[
    MetazoneRange(metazoneId: "Kamchatka", fromMs: null, toMs: null),
  ],
  "Asia/Karachi": <MetazoneRange>[
    MetazoneRange(metazoneId: "Karachi", fromMs: null, toMs: 38775600000),
    MetazoneRange(metazoneId: "Pakistan", fromMs: 38775600000, toMs: null),
  ],
  "Asia/Katmandu": <MetazoneRange>[
    MetazoneRange(metazoneId: "Nepal", fromMs: null, toMs: null),
  ],
  "Asia/Khandyga": <MetazoneRange>[
    MetazoneRange(metazoneId: "Yakutsk", fromMs: null, toMs: 1072882800000),
    MetazoneRange(
      metazoneId: "Vladivostok",
      fromMs: 1072882800000,
      toMs: 1315832400000,
    ),
    MetazoneRange(metazoneId: "Yakutsk", fromMs: 1315832400000, toMs: null),
  ],
  "Asia/Krasnoyarsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Krasnoyarsk", fromMs: null, toMs: null),
  ],
  "Asia/Kuala_Lumpur": <MetazoneRange>[
    MetazoneRange(metazoneId: "Malaya", fromMs: null, toMs: 378662400000),
    MetazoneRange(metazoneId: "Malaysia", fromMs: 378662400000, toMs: null),
  ],
  "Asia/Kuching": <MetazoneRange>[
    MetazoneRange(metazoneId: "Borneo", fromMs: null, toMs: 378662400000),
    MetazoneRange(metazoneId: "Malaysia", fromMs: 378662400000, toMs: null),
  ],
  "Asia/Kuwait": <MetazoneRange>[
    MetazoneRange(metazoneId: "Arabian", fromMs: null, toMs: null),
  ],
  "Asia/Macau": <MetazoneRange>[
    MetazoneRange(metazoneId: "Macau", fromMs: null, toMs: 945619200000),
    MetazoneRange(metazoneId: "China", fromMs: 945619200000, toMs: null),
  ],
  "Asia/Magadan": <MetazoneRange>[
    MetazoneRange(metazoneId: "Magadan", fromMs: null, toMs: null),
  ],
  "Asia/Makassar": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indonesia_Central", fromMs: null, toMs: null),
  ],
  "Asia/Manila": <MetazoneRange>[
    MetazoneRange(metazoneId: "Philippines", fromMs: null, toMs: null),
  ],
  "Asia/Muscat": <MetazoneRange>[
    MetazoneRange(metazoneId: "Gulf", fromMs: null, toMs: null),
  ],
  "Asia/Nicosia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Asia/Novokuznetsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Krasnoyarsk", fromMs: null, toMs: 1269716400000),
    MetazoneRange(
      metazoneId: "Novosibirsk",
      fromMs: 1269716400000,
      toMs: 1414263600000,
    ),
    MetazoneRange(metazoneId: "Krasnoyarsk", fromMs: 1414263600000, toMs: null),
  ],
  "Asia/Novosibirsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Novosibirsk", fromMs: null, toMs: 1469304000000),
    MetazoneRange(metazoneId: "Krasnoyarsk", fromMs: 1469304000000, toMs: null),
  ],
  "Asia/Omsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Omsk", fromMs: null, toMs: null),
  ],
  "Asia/Oral": <MetazoneRange>[
    MetazoneRange(metazoneId: "Uralsk", fromMs: null, toMs: 692827200000),
    MetazoneRange(
      metazoneId: "Oral",
      fromMs: 692827200000,
      toMs: 1099173600000,
    ),
    MetazoneRange(
      metazoneId: "Kazakhstan_Western",
      fromMs: 1099173600000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Phnom_Penh": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indochina", fromMs: null, toMs: null),
  ],
  "Asia/Pontianak": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Indonesia_Central",
      fromMs: null,
      toMs: 567964800000,
    ),
    MetazoneRange(
      metazoneId: "Indonesia_Western",
      fromMs: 567964800000,
      toMs: null,
    ),
  ],
  "Asia/Pyongyang": <MetazoneRange>[
    MetazoneRange(metazoneId: "Korea", fromMs: null, toMs: 1439564400000),
    MetazoneRange(
      metazoneId: "Pyongyang",
      fromMs: 1439564400000,
      toMs: 1525446000000,
    ),
    MetazoneRange(metazoneId: "Korea", fromMs: 1525446000000, toMs: null),
  ],
  "Asia/Qatar": <MetazoneRange>[
    MetazoneRange(metazoneId: "Gulf", fromMs: null, toMs: 76190400000),
    MetazoneRange(metazoneId: "Arabian", fromMs: 76190400000, toMs: null),
  ],
  "Asia/Qostanay": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Kazakhstan_Eastern",
      fromMs: 1099170000000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Qyzylorda": <MetazoneRange>[
    MetazoneRange(metazoneId: "Kizilorda", fromMs: null, toMs: 692823600000),
    MetazoneRange(
      metazoneId: "Qyzylorda",
      fromMs: 692823600000,
      toMs: 1099170000000,
    ),
    MetazoneRange(
      metazoneId: "Kazakhstan_Eastern",
      fromMs: 1099170000000,
      toMs: 1545328800000,
    ),
    MetazoneRange(
      metazoneId: "Kazakhstan_Western",
      fromMs: 1545328800000,
      toMs: 1709229600000,
    ),
    MetazoneRange(metazoneId: "Kazakhstan", fromMs: 1709229600000, toMs: null),
  ],
  "Asia/Rangoon": <MetazoneRange>[
    MetazoneRange(metazoneId: "Myanmar", fromMs: null, toMs: null),
  ],
  "Asia/Riyadh": <MetazoneRange>[
    MetazoneRange(metazoneId: "Arabian", fromMs: null, toMs: null),
  ],
  "Asia/Saigon": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indochina", fromMs: 171820800000, toMs: null),
  ],
  "Asia/Sakhalin": <MetazoneRange>[
    MetazoneRange(metazoneId: "Sakhalin", fromMs: null, toMs: 1414249200000),
    MetazoneRange(
      metazoneId: "Magadan",
      fromMs: 1414249200000,
      toMs: 1459008000000,
    ),
    MetazoneRange(metazoneId: "Magadan", fromMs: 1461686400000, toMs: null),
  ],
  "Asia/Samarkand": <MetazoneRange>[
    MetazoneRange(metazoneId: "Samarkand", fromMs: null, toMs: 370720800000),
    MetazoneRange(
      metazoneId: "Tashkent",
      fromMs: 370720800000,
      toMs: 386445600000,
    ),
    MetazoneRange(
      metazoneId: "Samarkand",
      fromMs: 386445600000,
      toMs: 683661600000,
    ),
    MetazoneRange(metazoneId: "Uzbekistan", fromMs: 683661600000, toMs: null),
  ],
  "Asia/Seoul": <MetazoneRange>[
    MetazoneRange(metazoneId: "Korea", fromMs: null, toMs: null),
  ],
  "Asia/Shanghai": <MetazoneRange>[
    MetazoneRange(metazoneId: "China", fromMs: null, toMs: null),
  ],
  "Asia/Singapore": <MetazoneRange>[
    MetazoneRange(metazoneId: "Singapore", fromMs: null, toMs: null),
  ],
  "Asia/Srednekolymsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Magadan", fromMs: null, toMs: 1414245600000),
    MetazoneRange(metazoneId: "Magadan", fromMs: 1461427200000, toMs: null),
  ],
  "Asia/Taipei": <MetazoneRange>[
    MetazoneRange(metazoneId: "Taipei", fromMs: null, toMs: null),
  ],
  "Asia/Tashkent": <MetazoneRange>[
    MetazoneRange(metazoneId: "Tashkent", fromMs: null, toMs: 670363200000),
    MetazoneRange(metazoneId: "Uzbekistan", fromMs: 670363200000, toMs: null),
  ],
  "Asia/Tbilisi": <MetazoneRange>[
    MetazoneRange(metazoneId: "Tbilisi", fromMs: null, toMs: 670370400000),
    MetazoneRange(metazoneId: "Georgia", fromMs: 670370400000, toMs: null),
  ],
  "Asia/Tehran": <MetazoneRange>[
    MetazoneRange(metazoneId: "Iran", fromMs: null, toMs: null),
  ],
  "Asia/Thimphu": <MetazoneRange>[
    MetazoneRange(metazoneId: "India", fromMs: null, toMs: 560025000000),
    MetazoneRange(metazoneId: "Bhutan", fromMs: 560025000000, toMs: null),
  ],
  "Asia/Tokyo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Japan", fromMs: null, toMs: null),
  ],
  "Asia/Tomsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Krasnoyarsk", fromMs: 1464465600000, toMs: null),
  ],
  "Asia/Ulaanbaatar": <MetazoneRange>[
    MetazoneRange(metazoneId: "Mongolia", fromMs: null, toMs: null),
  ],
  "Asia/Urumqi": <MetazoneRange>[
    MetazoneRange(metazoneId: "Urumqi", fromMs: null, toMs: null),
  ],
  "Asia/Ust-Nera": <MetazoneRange>[
    MetazoneRange(metazoneId: "Yakutsk", fromMs: null, toMs: 354898800000),
    MetazoneRange(
      metazoneId: "Magadan",
      fromMs: 354898800000,
      toMs: 1315828800000,
    ),
    MetazoneRange(metazoneId: "Vladivostok", fromMs: 1315828800000, toMs: null),
  ],
  "Asia/Vientiane": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indochina", fromMs: null, toMs: null),
  ],
  "Asia/Vladivostok": <MetazoneRange>[
    MetazoneRange(metazoneId: "Vladivostok", fromMs: null, toMs: null),
  ],
  "Asia/Yakutsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Yakutsk", fromMs: null, toMs: null),
  ],
  "Asia/Yekaterinburg": <MetazoneRange>[
    MetazoneRange(metazoneId: "Sverdlovsk", fromMs: null, toMs: 695772000000),
    MetazoneRange(
      metazoneId: "Yekaterinburg",
      fromMs: 695772000000,
      toMs: null,
    ),
  ],
  "Asia/Yerevan": <MetazoneRange>[
    MetazoneRange(metazoneId: "Yerevan", fromMs: null, toMs: 670370400000),
    MetazoneRange(metazoneId: "Armenia", fromMs: 670370400000, toMs: null),
  ],
  "Atlantic/Azores": <MetazoneRange>[
    MetazoneRange(metazoneId: "Azores", fromMs: null, toMs: 725421600000),
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: 725421600000,
      toMs: 740278800000,
    ),
    MetazoneRange(metazoneId: "Azores", fromMs: 740278800000, toMs: null),
  ],
  "Atlantic/Bermuda": <MetazoneRange>[
    MetazoneRange(metazoneId: "Atlantic", fromMs: null, toMs: null),
  ],
  "Atlantic/Canary": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Western", fromMs: null, toMs: null),
  ],
  "Atlantic/Cape_Verde": <MetazoneRange>[
    MetazoneRange(metazoneId: "Cape_Verde", fromMs: null, toMs: null),
  ],
  "Atlantic/Faeroe": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Western", fromMs: null, toMs: null),
  ],
  "Atlantic/Madeira": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Western", fromMs: null, toMs: null),
  ],
  "Atlantic/Reykjavik": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Atlantic/South_Georgia": <MetazoneRange>[
    MetazoneRange(metazoneId: "South_Georgia", fromMs: null, toMs: null),
  ],
  "Atlantic/St_Helena": <MetazoneRange>[
    MetazoneRange(metazoneId: "GMT", fromMs: null, toMs: null),
  ],
  "Atlantic/Stanley": <MetazoneRange>[
    MetazoneRange(metazoneId: "Falkland", fromMs: null, toMs: null),
  ],
  "Australia/Adelaide": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Central", fromMs: null, toMs: null),
  ],
  "Australia/Brisbane": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Eastern", fromMs: null, toMs: null),
  ],
  "Australia/Broken_Hill": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Central", fromMs: null, toMs: null),
  ],
  "Australia/Darwin": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Central", fromMs: null, toMs: null),
  ],
  "Australia/Eucla": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Australia_CentralWestern",
      fromMs: null,
      toMs: null,
    ),
  ],
  "Australia/Hobart": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Eastern", fromMs: null, toMs: null),
  ],
  "Australia/Lindeman": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Eastern", fromMs: null, toMs: null),
  ],
  "Australia/Lord_Howe": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Australia_Eastern",
      fromMs: null,
      toMs: 352216800000,
    ),
    MetazoneRange(metazoneId: "Lord_Howe", fromMs: 352216800000, toMs: null),
  ],
  "Australia/Melbourne": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Eastern", fromMs: null, toMs: null),
  ],
  "Australia/Perth": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Western", fromMs: null, toMs: null),
  ],
  "Australia/Sydney": <MetazoneRange>[
    MetazoneRange(metazoneId: "Australia_Eastern", fromMs: null, toMs: null),
  ],
  "Europe/Amsterdam": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Andorra": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Astrakhan": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Moscow",
      fromMs: 701820000000,
      toMs: 1459033200000,
    ),
    MetazoneRange(metazoneId: "Samara", fromMs: 1459033200000, toMs: null),
  ],
  "Europe/Athens": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Europe/Belgrade": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Berlin": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Bratislava": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Brussels": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Bucharest": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Europe/Budapest": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Busingen": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Chisinau": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 641944800000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 641944800000,
      toMs: null,
    ),
  ],
  "Europe/Copenhagen": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Dublin": <MetazoneRange>[
    MetazoneRange(metazoneId: "Irish", fromMs: null, toMs: 57722400000),
    MetazoneRange(metazoneId: "GMT", fromMs: 57722400000, toMs: null),
  ],
  "Europe/Gibraltar": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Guernsey": <MetazoneRange>[
    MetazoneRange(metazoneId: "British", fromMs: null, toMs: 57722400000),
    MetazoneRange(metazoneId: "GMT", fromMs: 57722400000, toMs: null),
  ],
  "Europe/Helsinki": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Europe/Isle_of_Man": <MetazoneRange>[
    MetazoneRange(metazoneId: "British", fromMs: null, toMs: 57722400000),
    MetazoneRange(metazoneId: "GMT", fromMs: 57722400000, toMs: null),
  ],
  "Europe/Istanbul": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: null,
      toMs: 267915600000,
    ),
    MetazoneRange(
      metazoneId: "Turkey",
      fromMs: 267915600000,
      toMs: 468111600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 468111600000,
      toMs: 1473195600000,
    ),
    MetazoneRange(metazoneId: "Turkey", fromMs: 1473195600000, toMs: null),
  ],
  "Europe/Jersey": <MetazoneRange>[
    MetazoneRange(metazoneId: "British", fromMs: null, toMs: 57722400000),
    MetazoneRange(metazoneId: "GMT", fromMs: 57722400000, toMs: null),
  ],
  "Europe/Kaliningrad": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 606870000000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 606870000000,
      toMs: 1301184000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Further_Eastern",
      fromMs: 1301184000000,
      toMs: 1414278000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 1414278000000,
      toMs: null,
    ),
  ],
  "Europe/Kiev": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 646783200000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 646783200000,
      toMs: null,
    ),
  ],
  "Europe/Kirov": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: 1414274400000, toMs: null),
  ],
  "Europe/Lisbon": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: null,
      toMs: 212544000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: 212544000000,
      toMs: 717555600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 717555600000,
      toMs: 828234000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Western",
      fromMs: 828234000000,
      toMs: null,
    ),
  ],
  "Europe/Ljubljana": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/London": <MetazoneRange>[
    MetazoneRange(metazoneId: "British", fromMs: null, toMs: 57722400000),
    MetazoneRange(metazoneId: "GMT", fromMs: 57722400000, toMs: null),
  ],
  "Europe/Luxembourg": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Madrid": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Malta": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Mariehamn": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Europe/Minsk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 670374000000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 670374000000,
      toMs: 1301184000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Further_Eastern",
      fromMs: 1301184000000,
      toMs: 1414360800000,
    ),
    MetazoneRange(metazoneId: "Moscow", fromMs: 1414360800000, toMs: null),
  ],
  "Europe/Monaco": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Moscow": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 670374000000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 670374000000,
      toMs: 695779200000,
    ),
    MetazoneRange(metazoneId: "Moscow", fromMs: 695779200000, toMs: null),
  ],
  "Europe/Oslo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Paris": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Podgorica": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Prague": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Riga": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 606870000000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 606870000000,
      toMs: null,
    ),
  ],
  "Europe/Rome": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Samara": <MetazoneRange>[
    MetazoneRange(metazoneId: "Kuybyshev", fromMs: null, toMs: 606866400000),
    MetazoneRange(
      metazoneId: "Moscow",
      fromMs: 606866400000,
      toMs: 670374000000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 670374000000,
      toMs: 686102400000,
    ),
    MetazoneRange(metazoneId: "Samara", fromMs: 686102400000, toMs: null),
  ],
  "Europe/San_Marino": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Sarajevo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Saratov": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Moscow",
      fromMs: 701820000000,
      toMs: 1480806000000,
    ),
    MetazoneRange(metazoneId: "Samara", fromMs: 1480806000000, toMs: null),
  ],
  "Europe/Simferopol": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 646786800000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 646786800000,
      toMs: 767739600000,
    ),
    MetazoneRange(
      metazoneId: "Moscow",
      fromMs: 767739600000,
      toMs: 859683600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 859683600000,
      toMs: 1396137600000,
    ),
    MetazoneRange(metazoneId: "Moscow", fromMs: 1396137600000, toMs: null),
  ],
  "Europe/Skopje": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Sofia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Eastern", fromMs: null, toMs: null),
  ],
  "Europe/Stockholm": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Tallinn": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 606870000000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 606870000000,
      toMs: null,
    ),
  ],
  "Europe/Tirane": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Ulyanovsk": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Moscow",
      fromMs: 695779200000,
      toMs: 1459033200000,
    ),
    MetazoneRange(metazoneId: "Samara", fromMs: 1459033200000, toMs: null),
  ],
  "Europe/Vaduz": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Vatican": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Vienna": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Vilnius": <MetazoneRange>[
    MetazoneRange(metazoneId: "Moscow", fromMs: null, toMs: 606870000000),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 606870000000,
      toMs: 891133200000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Central",
      fromMs: 891133200000,
      toMs: 941331600000,
    ),
    MetazoneRange(
      metazoneId: "Europe_Eastern",
      fromMs: 941331600000,
      toMs: null,
    ),
  ],
  "Europe/Volgograd": <MetazoneRange>[
    MetazoneRange(metazoneId: "Volgograd", fromMs: null, toMs: 1609020000000),
    MetazoneRange(metazoneId: "Moscow", fromMs: 1609020000000, toMs: null),
  ],
  "Europe/Warsaw": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Zagreb": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Europe/Zurich": <MetazoneRange>[
    MetazoneRange(metazoneId: "Europe_Central", fromMs: null, toMs: null),
  ],
  "Indian/Antananarivo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Indian/Chagos": <MetazoneRange>[
    MetazoneRange(metazoneId: "Indian_Ocean", fromMs: null, toMs: null),
  ],
  "Indian/Christmas": <MetazoneRange>[
    MetazoneRange(metazoneId: "Christmas", fromMs: null, toMs: null),
  ],
  "Indian/Cocos": <MetazoneRange>[
    MetazoneRange(metazoneId: "Cocos", fromMs: null, toMs: null),
  ],
  "Indian/Comoro": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Indian/Kerguelen": <MetazoneRange>[
    MetazoneRange(metazoneId: "French_Southern", fromMs: null, toMs: null),
  ],
  "Indian/Mahe": <MetazoneRange>[
    MetazoneRange(metazoneId: "Seychelles", fromMs: null, toMs: null),
  ],
  "Indian/Maldives": <MetazoneRange>[
    MetazoneRange(metazoneId: "Maldives", fromMs: null, toMs: null),
  ],
  "Indian/Mauritius": <MetazoneRange>[
    MetazoneRange(metazoneId: "Mauritius", fromMs: null, toMs: null),
  ],
  "Indian/Mayotte": <MetazoneRange>[
    MetazoneRange(metazoneId: "Africa_Eastern", fromMs: null, toMs: null),
  ],
  "Indian/Reunion": <MetazoneRange>[
    MetazoneRange(metazoneId: "Reunion", fromMs: null, toMs: null),
  ],
  "Pacific/Apia": <MetazoneRange>[
    MetazoneRange(metazoneId: "Apia", fromMs: null, toMs: null),
  ],
  "Pacific/Auckland": <MetazoneRange>[
    MetazoneRange(metazoneId: "New_Zealand", fromMs: null, toMs: null),
  ],
  "Pacific/Bougainville": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "Papua_New_Guinea",
      fromMs: null,
      toMs: 1419696000000,
    ),
  ],
  "Pacific/Chatham": <MetazoneRange>[
    MetazoneRange(metazoneId: "Chatham", fromMs: null, toMs: null),
  ],
  "Pacific/Easter": <MetazoneRange>[
    MetazoneRange(metazoneId: "Easter", fromMs: null, toMs: null),
  ],
  "Pacific/Efate": <MetazoneRange>[
    MetazoneRange(metazoneId: "Vanuatu", fromMs: null, toMs: null),
  ],
  "Pacific/Enderbury": <MetazoneRange>[
    MetazoneRange(metazoneId: "Phoenix_Islands", fromMs: null, toMs: null),
  ],
  "Pacific/Fakaofo": <MetazoneRange>[
    MetazoneRange(metazoneId: "Tokelau", fromMs: null, toMs: null),
  ],
  "Pacific/Fiji": <MetazoneRange>[
    MetazoneRange(metazoneId: "Fiji", fromMs: null, toMs: null),
  ],
  "Pacific/Funafuti": <MetazoneRange>[
    MetazoneRange(metazoneId: "Tuvalu", fromMs: null, toMs: null),
  ],
  "Pacific/Galapagos": <MetazoneRange>[
    MetazoneRange(metazoneId: "Ecuador", fromMs: null, toMs: 504939600000),
    MetazoneRange(metazoneId: "Galapagos", fromMs: 504939600000, toMs: null),
  ],
  "Pacific/Gambier": <MetazoneRange>[
    MetazoneRange(metazoneId: "Gambier", fromMs: null, toMs: null),
  ],
  "Pacific/Guadalcanal": <MetazoneRange>[
    MetazoneRange(metazoneId: "Solomon", fromMs: null, toMs: null),
  ],
  "Pacific/Guam": <MetazoneRange>[
    MetazoneRange(metazoneId: "Guam", fromMs: null, toMs: 977493600000),
    MetazoneRange(metazoneId: "Chamorro", fromMs: 977493600000, toMs: null),
  ],
  "Pacific/Honolulu": <MetazoneRange>[
    MetazoneRange(metazoneId: "Hawaii", fromMs: null, toMs: null),
  ],
  "Pacific/Kiritimati": <MetazoneRange>[
    MetazoneRange(metazoneId: "Line_Islands", fromMs: null, toMs: null),
  ],
  "Pacific/Kosrae": <MetazoneRange>[
    MetazoneRange(metazoneId: "Kosrae", fromMs: null, toMs: null),
  ],
  "Pacific/Kwajalein": <MetazoneRange>[
    MetazoneRange(metazoneId: "Kwajalein", fromMs: null, toMs: 745934400000),
    MetazoneRange(
      metazoneId: "Marshall_Islands",
      fromMs: 745934400000,
      toMs: null,
    ),
  ],
  "Pacific/Majuro": <MetazoneRange>[
    MetazoneRange(metazoneId: "Marshall_Islands", fromMs: null, toMs: null),
  ],
  "Pacific/Marquesas": <MetazoneRange>[
    MetazoneRange(metazoneId: "Marquesas", fromMs: null, toMs: null),
  ],
  "Pacific/Midway": <MetazoneRange>[
    MetazoneRange(metazoneId: "Bering", fromMs: null, toMs: 436363200000),
    MetazoneRange(metazoneId: "Samoa", fromMs: 436363200000, toMs: null),
  ],
  "Pacific/Nauru": <MetazoneRange>[
    MetazoneRange(metazoneId: "Nauru", fromMs: null, toMs: null),
  ],
  "Pacific/Niue": <MetazoneRange>[
    MetazoneRange(metazoneId: "Niue", fromMs: null, toMs: null),
  ],
  "Pacific/Norfolk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Norfolk", fromMs: null, toMs: null),
  ],
  "Pacific/Noumea": <MetazoneRange>[
    MetazoneRange(metazoneId: "New_Caledonia", fromMs: null, toMs: null),
  ],
  "Pacific/Pago_Pago": <MetazoneRange>[
    MetazoneRange(metazoneId: "Bering", fromMs: null, toMs: 436363200000),
    MetazoneRange(metazoneId: "Samoa", fromMs: 436363200000, toMs: null),
  ],
  "Pacific/Palau": <MetazoneRange>[
    MetazoneRange(metazoneId: "Palau", fromMs: null, toMs: null),
  ],
  "Pacific/Pitcairn": <MetazoneRange>[
    MetazoneRange(metazoneId: "Pitcairn", fromMs: null, toMs: null),
  ],
  "Pacific/Ponape": <MetazoneRange>[
    MetazoneRange(metazoneId: "Ponape", fromMs: null, toMs: null),
  ],
  "Pacific/Port_Moresby": <MetazoneRange>[
    MetazoneRange(metazoneId: "Papua_New_Guinea", fromMs: null, toMs: null),
  ],
  "Pacific/Rarotonga": <MetazoneRange>[
    MetazoneRange(metazoneId: "Cook", fromMs: null, toMs: null),
  ],
  "Pacific/Saipan": <MetazoneRange>[
    MetazoneRange(
      metazoneId: "North_Mariana",
      fromMs: null,
      toMs: 977493600000,
    ),
    MetazoneRange(metazoneId: "Chamorro", fromMs: 977493600000, toMs: null),
  ],
  "Pacific/Tahiti": <MetazoneRange>[
    MetazoneRange(metazoneId: "Tahiti", fromMs: null, toMs: null),
  ],
  "Pacific/Tarawa": <MetazoneRange>[
    MetazoneRange(metazoneId: "Gilbert_Islands", fromMs: null, toMs: null),
  ],
  "Pacific/Tongatapu": <MetazoneRange>[
    MetazoneRange(metazoneId: "Tonga", fromMs: null, toMs: null),
  ],
  "Pacific/Truk": <MetazoneRange>[
    MetazoneRange(metazoneId: "Truk", fromMs: null, toMs: null),
  ],
  "Pacific/Wake": <MetazoneRange>[
    MetazoneRange(metazoneId: "Wake", fromMs: null, toMs: null),
  ],
  "Pacific/Wallis": <MetazoneRange>[
    MetazoneRange(metazoneId: "Wallis", fromMs: null, toMs: null),
  ],
};
