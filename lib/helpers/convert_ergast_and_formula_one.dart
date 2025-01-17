/*
 *  This file is part of BoxBox (https://github.com/BrightDV/BoxBox).
 * 
 * BoxBox is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BoxBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BoxBox.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2022, BrightDV
 */

class Converter {
  String driversFromFormulaOneToErgast(String driverCode) {
    Map formulaOneToErgast = {
      'VER': 'max_verstappen',
      'LEC': 'leclerc',
      'SAI': 'sainz',
      'RUS': 'russell',
      'HAM': 'hamilton',
      'OCO': 'ocon',
      'PER': 'perez',
      'MAG': 'kevin_magnussen',
      'BOT': 'bottas',
      'NOR': 'norris',
      'TSU': 'tsunoda',
      'GAS': 'gasly',
      'ALO': 'alonso',
      'ZHO': 'zhou',
      'MSC': 'mick_schumacher',
      'STR': 'stroll',
      'VET': 'vettel',
      'ALB': 'albon',
      'RIC': 'ricciardo',
      'LAT': 'latifi',
    };
    return formulaOneToErgast[driverCode];
  }

  String teamsFromFormulaOneToErgast(String teamName) {
    Map formulaOneToErgast = {
      'Red Bull Racing RBPT': 'red_bull',
      'Ferrari': 'ferrari',
      'Mercedes': 'mercedes',
      'Alpine Renault': 'alpine',
      'McLaren Mercedes': 'mclaren',
      'AlphaTauri RBPT': 'alphatauri',
      'Aston Martin Aramco Mercedes': 'aston_martin',
      'Williams Mercedes': 'williams',
      'Alfa Romeo Ferrari': 'alfa',
      'Haas Ferrari': 'haas',
    };
    return formulaOneToErgast[teamName];
  }

  // The following function has to be updated every year

  String circuitIdFromErgastToFormulaOne(String circuitId) {
    Map ergastToFormulaOne = {
      'bahrain': '1124',
      'jeddah': '1125',
      'albert_park': '1108',
      'imola': '1109',
      'miami': '1110',
      'catalunya': '1111',
      'monaco': '1112',
      'baku': '1126',
      'villeneuve': '1113',
      'silverstone': '1114',
      'red_bull_ring': '1115',
      'ricard': '1116',
      'hungaroring': '1117',
      'spa': '1118',
      'zandvoort': '1119',
      'monza': '1120',
      'marina_bay': '1133',
      'suzuka': '1134',
      'americas': '1135',
      'rodriguez': '1136',
      'interlagos': '1137',
      'yas_marina': '1138',
    };
    return ergastToFormulaOne[circuitId];
  }

  String circuitNameFromErgastToFormulaOne(String circuitId) {
    Map ergastToFormulaOne = {
      'bahrain': 'bahrain',
      'jeddah': 'saudi-arabia',
      'albert_park': 'australia',
      'imola': 'italy',
      'miami': 'miami',
      'catalunya': 'spain',
      'monaco': 'monaco',
      'baku': 'azerbaijan',
      'villeneuve': 'canada',
      'silverstone': 'great-britain',
      'red_bull_ring': 'austria',
      'ricard': 'france',
      'hungaroring': 'hungary',
      'spa': 'belgium',
      'zandvoort': 'netherlands',
      'monza': 'italy',
      'marina_bay': 'singapore',
      'suzuka': 'japan',
      'americas': 'united-states',
      'rodriguez': 'mexico',
      'interlagos': 'brazil',
      'yas_marina': 'abu-dhabi',
    };
    return ergastToFormulaOne[circuitId];
  }

  String driverIdFromErgast(String driverId) {
    Map ergastToFormulaOne = {
      "leclerc": "charles-leclerc",
      "sainz": "carlos-sainz",
      "max_verstappen": "max-verstappen",
      "russell": "george-russell",
      "hamilton": "lewis-hamilton",
      "ocon": "esteban-ocon",
      "perez": "sergio-perez",
      "kevin_magnussen": "kevin-magnussen",
      "bottas": "valtteri-bottas",
      "norris": "lando-norris",
      "tsunoda": "yuki-tsunoda",
      "gasly": "pierre-gasly",
      "alonso": "fernando-alonso",
      "zhou": "guanyu-zhou",
      "mick_schumacher": "mick-schumacher",
      "stroll": "lance-stroll",
      "hulkenberg": "nico-hulkenberg",
      "albon": "alexander-albon",
      "ricciardo": "daniel-ricciardo",
      "latifi": "nicholas-latifi",
      "vettel": "sebastian-vettel",
    };
    return ergastToFormulaOne[driverId];
  }
}
