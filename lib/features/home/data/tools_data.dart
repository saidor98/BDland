import 'package:flutter/material.dart';
import '../models/tool_item.dart';

// Tool Screen Imports
import '../../tools/01_google_map_survey/google_map_survey_screen.dart';
import '../../tools/02_mouza_simple/mouza_map_simple_screen.dart';
import '../../tools/03_mouza_advance_cad/mouza_map_advance_cad_screen.dart';
import '../../tools/04_anyshape_divider/anyshape_divider_screen.dart';
import '../../tools/05_quadmaster/quadmaster_screen.dart';
import '../../tools/06_all_mouza_maps/all_mouza_maps_screen.dart';
import '../../tools/07_mouza_google_overlay/mouza_map_overlay_screen.dart';
import '../../tools/08_comparative_pantograph/comparative_pantograph_screen.dart';
import '../../tools/09_map_joint_stitch/map_joint_stitch_screen.dart';
import '../../tools/10_multi_shape_geometry/multi_shape_geometry_screen.dart';
import '../../tools/11_ana_gonda_converter/ana_gonda_converter_screen.dart';
import '../../tools/12_map_converter/map_converter_screen.dart';
import '../../tools/13_unknown_side_solver/unknown_side_solver_screen.dart';
import '../../tools/14_smart_unit_converter/smart_land_unit_converter_screen.dart';
import '../../tools/15_land_ratio_divider/land_ratio_divider_screen.dart';
import '../../tools/16_dag_share/dag_share_calculator_screen.dart';
import '../../tools/17_khatian_analyzer/khatian_analyzer_screen.dart';
import '../../tools/18_muslim_faraiz/muslim_faraiz_screen.dart';
import '../../tools/19_hindu_inheritance/hindu_inheritance_screen.dart';
import '../../tools/20_hissya_calculator/hissya_calculator_screen.dart';
import '../../tools/21_tofsil_partition/tofsil_partition_screen.dart';
import '../../tools/22_print_studio/print_studio_screen.dart';
import '../../tools/23_survey_formulas/land_survey_formulas_screen.dart';
import '../../tools/24_surveyor_memo/surveyor_memo_screen.dart';
import '../../tools/25_name_share_calculator/name_share_calculator_screen.dart';

class ToolsData {
  ToolsData._();

  static final List<ToolItem> allTools = [
    ToolItem(
      id: 'tool_01_google_map',
      number: 1,
      title: 'গুগল ম্যাপে জমি পরিমাপ',
      subtitle: 'স্যাটেলাইট ম্যাপে প্লট এঁকে সহজে জমি পরিমাপ',
      icon: Icons.satellite_alt_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const GoogleMapSurveyScreen(),
      keywords: ['google map', 'satellite', 'পরিমাপ', 'ম্যাপ', 'প্লট', 'জমি', 'area'],
    ),
    ToolItem(
      id: 'tool_02_mouza_simple',
      number: 2,
      title: 'মৌজা ম্যাপ পরিমাপ (সহজ)',
      subtitle: 'মৌজা ম্যাপে সহজে জমি মাপুন ও ভাগ করুন',
      icon: Icons.architecture_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const MouzaMapSimpleScreen(),
      keywords: ['mouza', 'মৌজা', 'ম্যাপ', 'স্কেল', 'পরিমাপ', 'গুনিয়া', 'links'],
    ),
    ToolItem(
      id: 'tool_03_mouza_cad',
      number: 3,
      title: 'মৌজা ম্যাপ পরিমাপ (অ্যাডভান্স)',
      subtitle: 'CAD-মানের মাপ, ভাগবণ্টন, DXF ও স্ন্যাপিং',
      icon: Icons.polyline_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const MouzaMapAdvanceCadScreen(),
      keywords: ['cad', 'dxf', 'advance', 'স্ন্যাপিং', 'ভাগবণ্টন', 'অ্যাডভান্স'],
    ),
    ToolItem(
      id: 'tool_04_anyshape_divider',
      number: 4,
      title: 'AnyShape Divider',
      subtitle: 'যেকোনো আকৃতির জমি পরিমাপ ও ভাগবণ্টন',
      icon: Icons.pentagon_outlined,
      badgeText: 'নতুন',
      screenBuilder: (ctx) => const AnyShapeDividerScreen(),
      keywords: ['anyshape', 'divider', 'ভাগবণ্টন', 'বহুভুজ', 'polygon', 'বিভাজন'],
    ),
    ToolItem(
      id: 'tool_05_quadmaster',
      number: 5,
      title: 'চতুর্ভুজ পরিমাপ ও বণ্টন',
      subtitle: 'QuadMaster (৪ বাহু ও কর্ণ)',
      icon: Icons.crop_square_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const QuadMasterScreen(),
      keywords: ['quadmaster', 'চতুর্ভুজ', 'heron', 'হিরন', 'আমিন পদ্ধতি', 'গড় পদ্ধতি'],
    ),
    ToolItem(
      id: 'tool_06_all_mouza_maps',
      number: 6,
      title: 'সকল মৌজা ম্যাপ',
      subtitle: 'সারাদেশের সকল মৌজা ম্যাপ',
      icon: Icons.map_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const AllMouzaMapsScreen(),
      keywords: ['all mouza', 'সকল মৌজা', 'জেএল নং', 'ম্যাপ ডিরেক্টরি', 'বিভাগ', 'জেলা'],
    ),
    ToolItem(
      id: 'tool_07_mouza_overlay',
      number: 7,
      title: 'গুগল ম্যাপে মৌজা ম্যাপ',
      subtitle: 'মৌজা ম্যাপ বসিয়ে KMZ তৈরি',
      icon: Icons.layers_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const MouzaMapOverlayScreen(),
      keywords: ['overlay', 'kmz', 'kml', 'ওভারলে', 'সুপারইম্পোজ', 'georeference'],
    ),
    ToolItem(
      id: 'tool_08_pantograph',
      number: 8,
      title: 'তুলনামূলক প্যান্টোগ্রাফ',
      subtitle: 'সাবেক ও নতুন ম্যাপ তুলনা',
      icon: Icons.compare_arrows_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const ComparativePantographScreen(),
      keywords: ['pantograph', 'প্যান্টোগ্রাফ', 'তুলনা', 'সিএস', 'আরএস', 'বিএস', 'shift'],
    ),
    ToolItem(
      id: 'tool_09_map_joint',
      number: 9,
      title: 'ম্যাপ জয়েন্ট',
      subtitle: 'একাধিক সিট জয়েন করুন',
      icon: Icons.join_inner_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const MapJointStitchScreen(),
      keywords: ['map joint', 'ম্যাপ জয়েন্ট', 'স্টিচ', 'জোড়া', 'sheet stitch'],
    ),
    ToolItem(
      id: 'tool_10_multi_shape',
      number: 10,
      title: 'জমি পরিমাপ',
      subtitle: 'যেকোনো আকৃতির জমি পরিমাপ',
      icon: Icons.square_foot_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const MultiShapeGeometryScreen(),
      keywords: ['জমি পরিমাপ', 'ত্রিভুজ', 'আয়তক্ষেত্র', 'ট্রাপিজিয়াম', 'বৃত্ত', 'geometry'],
    ),
    ToolItem(
      id: 'tool_11_ana_gonda',
      number: 11,
      title: 'আনা-গণ্ডা কনভার্টার',
      subtitle: 'প্রথাগত জমির একক রূপান্তর',
      icon: Icons.sync_alt_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const AnaGondaConverterScreen(),
      keywords: ['আনা', 'গণ্ডা', 'কড়া', 'ক্রান্তি', 'তিল', 'ana', 'gonda', 'kora', 'kranti', 'til'],
    ),
    ToolItem(
      id: 'tool_12_map_converter',
      number: 12,
      title: 'Map Converter',
      subtitle: 'ফরম্যাট কনভার্ট ও ক্লিন',
      icon: Icons.photo_filter_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const MapConverterScreen(),
      keywords: ['map converter', 'কনভার্ট', 'ক্লিন', 'ফিল্টার', 'threshold', 'contrast'],
    ),
    ToolItem(
      id: 'tool_13_unknown_side',
      number: 13,
      title: 'ক্ষেত্রফল/অজানা বাহু',
      subtitle: 'অজানা বাহু নির্ণয় করুন',
      icon: Icons.calculate_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const UnknownSideSolverScreen(),
      keywords: ['অজানা বাহু', 'unknown side', 'প্রস্থ', 'দৈর্ঘ্য', 'ক্ষেত্রফল'],
    ),
    ToolItem(
      id: 'tool_14_smart_converter',
      number: 14,
      title: 'শতক-কাঠা-বিঘা-একর রূপান্তর',
      subtitle: 'কাস্টম মাপসহ স্মার্ট ভূমি একক কনভার্টার',
      icon: Icons.swap_horiz_outlined,
      badgeText: 'নতুন',
      screenBuilder: (ctx) => const SmartLandUnitConverterScreen(),
      keywords: ['শতক', 'কাঠা', 'বিঘা', 'একর', 'কানি', 'বর্গফুট', 'converter', 'unit'],
    ),
    ToolItem(
      id: 'tool_15_ratio_divider',
      number: 15,
      title: 'অনুপাত ক্যালকুলেটর',
      subtitle: 'জমির অনুপাত হিসাব',
      icon: Icons.pie_chart_outline,
      badgeText: null,
      screenBuilder: (ctx) => const LandRatioDividerScreen(),
      keywords: ['অনুপাত', 'ratio', 'বণ্টন', 'frontage', 'রাস্তার মুখ'],
    ),
    ToolItem(
      id: 'tool_16_dag_share',
      number: 16,
      title: 'দাগের অংশ',
      subtitle: 'দাগের মধ্যে তার অংশ নির্ণয়',
      icon: Icons.grid_4x4_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const DagShareCalculatorScreen(),
      keywords: ['দাগ', 'দাগের অংশ', 'প্লট', 'plot', 'dag', 'হিস্যা'],
    ),
    ToolItem(
      id: 'tool_17_khatian_analyzer',
      number: 17,
      title: 'খতিয়ান বিশ্লেষণ',
      subtitle: 'খতিয়ান পর্যালোচনা করুন',
      icon: Icons.manage_search_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const KhatianAnalyzerScreen(),
      keywords: ['খতিয়ান', 'khatian', 'porcha', 'পর্চা', 'মালিক', '১৬ আনা'],
    ),
    ToolItem(
      id: 'tool_18_muslim_faraiz',
      number: 18,
      title: 'উত্তরাধিকার (মুসলিম)',
      subtitle: 'মুসলিম আইন অনুযায়ী বণ্টন',
      icon: Icons.account_tree_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const MuslimFaraizScreen(),
      keywords: ['ফারায়েজ', 'উত্তরাধিকার', 'মুসলিম', 'faraiz', 'ওয়ারিশ', 'আওল', 'রদ'],
    ),
    ToolItem(
      id: 'tool_19_hindu_inheritance',
      number: 19,
      title: 'উত্তরাধিকার (হিন্দু)',
      subtitle: 'হিন্দু আইন অনুযায়ী বণ্টন',
      icon: Icons.hub_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const HinduInheritanceScreen(),
      keywords: ['হিন্দু উত্তরাধিকার', 'দায়ভাগ', 'dayabhaga', 'hindu inheritance'],
    ),
    ToolItem(
      id: 'tool_20_hissya_calculator',
      number: 20,
      title: 'হিস্যা ক্যালকুলেটর',
      subtitle: 'উত্তরাধিকার হিস্যা হিসাব',
      icon: Icons.pie_chart_outline,
      badgeText: null,
      screenBuilder: (ctx) => const HissyaCalculatorScreen(),
      keywords: ['হিস্যা', 'অংশ', 'যোগ', 'বিয়োগ', 'হিসাব', 'hissya'],
    ),
    ToolItem(
      id: 'tool_21_tofsil_partition',
      number: 21,
      title: 'তফসিল বণ্টন',
      subtitle: 'তফসিল অনুযায়ী বণ্টন',
      icon: Icons.table_chart_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const TofsilPartitionScreen(),
      keywords: ['তফসিল', 'চৌহদ্দি', 'দলিল', 'tofsil', 'schedule'],
    ),
    ToolItem(
      id: 'tool_22_print_studio',
      number: 22,
      title: 'প্রিন্ট স্টুডিও',
      subtitle: 'নকশা সাজিয়ে A4 প্রিন্ট, PDF ও শেয়ার',
      icon: Icons.print_outlined,
      badgeText: 'PRO',
      screenBuilder: (ctx) => const PrintStudioScreen(),
      keywords: ['প্রিন্ট', 'pdf', 'a4', 'print studio', 'সার্টিফিকেট', 'নকশা'],
    ),
    ToolItem(
      id: 'tool_23_survey_formulas',
      number: 23,
      title: 'জমির সকল সূত্র',
      subtitle: 'সব হিসাবের সূত্র এক জায়গায়',
      icon: Icons.menu_book_outlined,
      badgeText: null,
      screenBuilder: (ctx) => const LandSurveyFormulasScreen(),
      keywords: ['সূত্র', 'গান্টার চেইন', 'লিংক', 'নামজারি', 'ফি', 'খাজনা', 'formula'],
    ),
    ToolItem(
      id: 'tool_24_surveyor_memo',
      number: 24,
      title: 'সার্ভেয়ার মেমো',
      subtitle: 'কাজের হিসাব ও বিল তৈরি',
      icon: Icons.receipt_long_outlined,
      badgeText: 'নতুন',
      screenBuilder: (ctx) => const SurveyorMemoScreen(),
      keywords: ['মেমো', 'বিল', 'ভাউচার', 'সার্ভেয়ার', 'memo', 'invoice', 'খরচ'],
    ),
    ToolItem(
      id: 'tool_25_name_share',
      number: 25,
      title: 'নামের অংশ ক্যালকুলেটর',
      subtitle: 'নাম অনুযায়ী অংশ, আনা-গণ্ডা ও জমি হিসাব',
      icon: Icons.badge_outlined,
      badgeText: 'নতুন',
      screenBuilder: (ctx) => const NameShareCalculatorScreen(),
      keywords: ['নাম', 'নামের অংশ', 'মালিক', 'অংশীদার', 'খতিয়ান', 'নামজারি', 'হিস্যা', 'name share'],
    ),
  ];
}
