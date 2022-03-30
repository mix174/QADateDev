//
//  QADate.swift
//  ReportingSystem
//
//  Created by Maxim Vakhbe on 21.01.2022.
//

import Foundation

// MARK: - Components

enum Components: CaseIterable {
    case year
    case month
    case hour
    case min
    case sec
    case miliSec
    case day
}

// MARK: - DateFormat

/// Общий enum для DateFormat  с возможностью задавать как кастомную строку так и спец.кейсы
/// Создан для упрощения работы с DateFormat и сокращения конвертеров
enum CommonDateFormat {
    case custom(String)
    case dateFormat(DateFormat)

    func get() -> String {
        switch self {
        case let .custom(string):
            return string
        case let .dateFormat(string):
            return string.rawValue
        }
    }
}

enum DateFormat: String {
    /// Формат даты: dd.MM.yyyy — День.Месяц.Год
    case dayMonthYear = "dd.MM.yyyy"
    /// Формат даты: dd.MM — День.Месяц
    case dayMonth = "dd.MM"
    /// Формат даты: MM.yyyy — Месяц (строковый) Год
    case monthYearLocale = "LLLL yyyy"
    /// Формат даты: yyyy — Год
    case year = "yyyy"
    /// Формат даты: yyyy-MM-dd'T'HH:mm:ss - год-месяц-день часы:минуты:секунды
    case yearMothDayTime = "yyyy-MM-dd'T'HH:mm:ss"
}

typealias QADateComponets = (year: Int?, month: Int?, day: Int?)?

// MARK: - QADate

public struct QADate {
    
    // MARK: - Preperties
    private var dateComponents: DateComponents
    private let calendar: Calendar
    
    var year: Int? {
        dateComponents.year
    }

    var month: Int? {
        dateComponents.month
    }

    var day: Int? {
        dateComponents.day
    }

    var hour: Int? {
        dateComponents.hour
    }

    var min: Int? {
        dateComponents.minute
    }

    var sec: Int? {
        dateComponents.second
    }

    var miliSec: Int? {
        dateComponents.nanosecond
    }

    /// 1 - sunday
    var weekDay: Int? {
        guard let date = dateComponents.date else { return nil }
        return calendar.component(.weekday, from: date)
    }

    /// true, если месяц високосный
    var isLeapMonth: Bool? {
        dateComponents.isLeapMonth
    }

    /// Дата (Date()), сформированная из установленных компонентов
    /// Для вывода лучше использовать getDefaultString или getCustomString
    public var date: Date? {
        return dateComponents.date
    }
    
    // MARK: - Init
    /// основной инит с проверкой и исправлением значений
    /// Все параметры опциональные с предустановленными значения, можно удалять ненужные из инита
    init(calendar: Calendar? = nil, timeZone: TimeZone? = nil, year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, min: Int? = nil, sec: Int? = nil, miliSec: Int? = nil) {
        let actualCalendar = calendar ?? Calendar.current
        let actualTimeZone = timeZone ?? TimeZone.current
        self.calendar = actualCalendar
        let components = DateComponents(calendar: actualCalendar, timeZone: actualTimeZone, era: nil, year: year, month: month, day: day, hour: hour, minute: min, second: sec, nanosecond: miliSec, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let validatedComponents = QADate.validate(components: components)
        self.dateComponents = validatedComponents
    }

    /// инит с текущим временем по умолчанию
    public init(calendar: Calendar?, timeZone: TimeZone? = nil) {
        let actualCalendar = calendar ?? Calendar.current
        self.calendar = actualCalendar
        let meta = actualCalendar.dateComponents(in: timeZone ?? TimeZone.current, from: Date())
        self.dateComponents = DateComponents(calendar: actualCalendar, timeZone: timeZone, era: meta.era, year: meta.year, month: meta.month, day: meta.day, hour: meta.hour, minute: meta.minute, second: meta.second, nanosecond: meta.nanosecond, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
    }

    /// инит со всеми текущими данными по умолчанию
    public init() {
        // Промежуточное значение, так как если сразу импортировать из Date() в self.dateComponents, то есть баги
        let meta = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        self.calendar = Calendar.current
        self.dateComponents = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, era: nil, year: meta.year, month: meta.month, day: meta.day, hour: meta.hour, minute: meta.minute, second: meta.second, nanosecond: meta.nanosecond, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
    }
    
    init?(_ stringDate: String, format: CommonDateFormat) {
        guard let date = QADate.convert(date: stringDate, type: format.get()) else { return nil }
        let meta = Calendar.current.dateComponents(in: TimeZone.current, from: date)
        self.calendar = Calendar.current
        self.dateComponents = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, era: nil, year: meta.year, month: meta.month, day: meta.day, hour: meta.hour, minute: meta.minute, second: meta.second, nanosecond: meta.nanosecond, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
    }
    
    // MARK: - Output
    /// получение строки с одним из предустановленных в DateFormat варианте
    func getDefaultString(in format: DateFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format.rawValue
        
        guard let date = dateComponents.date else {
            return "" // можно так?
        }
        return formatter.string(from: date).capitalized
    }

    /// получение строки с кастомным форматом
    func getCustomString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        guard let date = dateComponents.date else {
            return "" // можно так?
        }
        return formatter.string(from: date).capitalized
    }
    
    // MARK: - Change
    /// увеличение или уменьшение компонента (можно поменять 1 компонент за раз)
    /// при увеличении/уменьшении 1 компонента, остальные меняются автоматически
    /// для увеличения - toIncrease: true (по умолчанию), для уменьшения: fasle
    mutating func change(component: Components, by value: Int, toIncrease: Bool = true) {
        switch component {
        case .year:
            guard let year = dateComponents.year else { return }
            dateComponents.year = toIncrease ? year + value : year - value
        case .month:
            guard let month = dateComponents.month else { return }
            dateComponents.month = toIncrease ? month + value : month - value
        case .day:
            guard let day = dateComponents.day else { return }
            dateComponents.day = toIncrease ? day + value : day - value
        case .hour:
            guard let hour = dateComponents.hour else { return }
            dateComponents.hour = toIncrease ? hour + value : hour - value
        case .min:
            guard let min = dateComponents.minute else { return }
            dateComponents.minute = toIncrease ? min + value : min - value
        case .sec:
            guard let sec = dateComponents.second else { return }
            dateComponents.second = toIncrease ? sec + value : sec - value
        case .miliSec:
            guard let miliSec = dateComponents.nanosecond else { return }
            dateComponents.nanosecond = toIncrease ? miliSec + value : miliSec - value
        }
        // здесь происходит изменение остальных параметров автоматически
        guard let date = dateComponents.date else { return }
        // важно перезаписывать только то, что инициализировано при ините, поэтому есть проверки
        if year != nil {
            dateComponents.year = calendar.component(.year, from: date)
        }
        if month != nil {
            dateComponents.month = calendar.component(.month, from: date)
        }
        if day != nil {
            dateComponents.day = calendar.component(.day, from: date)
        }
        if hour != nil {
            dateComponents.hour = calendar.component(.hour, from: date)
        }
        if min != nil {
            dateComponents.minute = calendar.component(.minute, from: date)
        }
        if sec != nil {
            dateComponents.second = calendar.component(.second, from: date)
        }
        if miliSec != nil {
            dateComponents.nanosecond = calendar.component(.nanosecond, from: date)
        }
    }
    
    //MARK: - Comparing
    /// сравнение по 1 компоненту
    /// при сравнении nil -> false
    func isEqual(component: Components, with comparison: QADate) -> Bool {
        switch component {
        case .year:
            return QADate.compare(self.year, with: comparison.year)
        case .month:
            return QADate.compare(self.month, with: comparison.month)
        case .day:
            return QADate.compare(self.day, with: comparison.day)
        case .hour:
            return QADate.compare(self.hour, with: comparison.hour)
        case .min:
            return QADate.compare(self.min, with: comparison.min)
        case .sec:
            return QADate.compare(self.sec, with: comparison.sec)
        case .miliSec:
            return QADate.compare(self.miliSec, with: comparison.miliSec)
        }
    }

    /// Проверка на совпадение года
    func isSameYear(in comparison: QADate) -> Bool {
        if QADate.compare(self.year, with: comparison.year) {
            return true
        } else {
            return false
        }
    }

    /// Проверка на совпадение месяца и года
    func isSameMonth(in comparison: QADate) -> Bool {
        if QADate.compare(self.month, with: comparison.month) && isSameYear(in: comparison) {
            return true
        } else {
            return false
        }
    }

    /// Проверка на совпадение дня, месяца и года
    func isToday(in comparison: QADate) -> Bool {
        if QADate.compare(self.day, with: comparison.day) && isSameMonth(in: comparison) {
            return true
        } else {
            return false
        }
    }

    /// Проверка на совпадение Date()
    func isSameDate(with comparison: QADate) -> Bool {
        guard let comparisonDate = comparison.date,
              let selfDate = dateComponents.date else { return false }
        if selfDate == comparisonDate {
            return true
        } else {
            return false
        }
    }

    /// сравнение по date на "текущая Date() реньше чем у сравняемого объекта"
    func isEarlier(than comparison: QADate) -> Bool {
        guard let comparisonDate = comparison.date,
              let selfDate = dateComponents.date else { return false }
        if selfDate < comparisonDate {
            return true
        } else {
            return false
        }
    }

    /// сравнение по date на "текущая Date() позже чем у сравняемого объекта"
    func isLater(than comparison: QADate) -> Bool {
        guard let comparisonDate = comparison.date,
              let selfDate = dateComponents.date else { return false }
        if selfDate > comparisonDate {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Static Extension QADate

extension QADate {

    // MARK: - Internal static funcs
    /// аналогие на min(x,y): возвращает более раннюю дату (сравнивается Date())
    static func yarlyDate(_ firstDate: QADate, _ secondDate: QADate) -> QADate? {
        guard let first = firstDate.date,
              let second = secondDate.date else { return nil }
        if first <= second {
            return firstDate
        } else {
            return secondDate
        }
    }

    /// аналогия на max(x,y): возвращает более позднюю дату (сравнивается Date())
    static func lateDate(_ firstDate: QADate, _ secondDate: QADate) -> QADate? {
        guard let first = firstDate.date,
              let second = secondDate.date else { return nil }
        if first >= second {
            return firstDate
        } else {
            return secondDate
        }
    }

    /// Конвертирует строковую дату из входного формата в один из доступных в DateFormat
    static func convert(date: String, from innerFormat: String, to outerFormat: DateFormat) -> String? {
        guard let dateConverted: Date = self.convert(date: date, type: innerFormat) else { return nil }
        return self.convert(date: dateConverted, type: outerFormat)
    }

    /// Конвертация даты с заданным форматом в строку
    /// - Parameters:
    ///   - date: Дата
    ///   - dateFormat: формат вывода даты
    /// - Returns: строка с датой
    static func convert(date: Date, type dateFormat: DateFormat) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat.rawValue
        return dateFormatter.string(from: date)
    }

    /// Конвертация строки, в зависимости от выбранного формата даты, в кортеж с годом, месяцем, днем
    /// - Parameters:
    ///   - date: строка с датой
    ///   - dateFormat: формат даты
    /// - Returns: кортеж с годом, месяцем, днем
    static func convert(date: String?, type dateFormat: DateFormat) -> QADateComponets {
        guard let date = date else { return nil }
        var dateArray: [String] = []
        switch dateFormat {
        case .dayMonthYear:
            dateArray = date.components(separatedBy: ".")
            return (year: Int(dateArray[2]), month: Int(dateArray[1]), day: Int(dateArray[0]))
        case .dayMonth:
            dateArray = date.components(separatedBy: ".")
            return (year: nil, month: Int(dateArray[1]), day: Int(dateArray[0]))
        case .year:
            dateArray.append(date)
            return (year: Int(dateArray[0]), month: nil, day: nil)
        default: return nil
        }
    }

    /// Конвертация строки с датой с определенным форматом в Date?
    /// - Parameters:
    ///   - date: строковая дата
    ///   - dateFormat: формат даты
    /// - Returns: дата типа Date?
    static func convert(date: String, type dateFormat: DateFormat) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat.rawValue
        guard let dateConverted: Date = dateFormatter.date(from: date) else { return nil }
        return dateConverted
    }

    /// Конвертация строки с датой с определенным форматом, который задается строкой в Date?
    /// - Parameters:
    ///   - date: строковая дата
    ///   - dateFormat: формат даты, задется строкой
    /// - Returns: дата типа Date?
    static func convert(date: String, type dateFormat: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        guard let dateConverted: Date = dateFormatter.date(from: date) else { return nil }
        return dateConverted
    }

    /// Конвертирует строковую дату из входного формата в один из доступных в DateFormat
    static func convert(date: String, from innerFormat: CommonDateFormat, to outerFormat: CommonDateFormat) -> String? {
        guard let dateConverted: Date = self.convert(date: date, type: innerFormat.get()),
              let outerFormat = DateFormat(rawValue: outerFormat.get()) else {
                  return nil
              }
        return self.convert(date: dateConverted, type: outerFormat)
    }
}

// MARK: - Private Extension QADate

private extension QADate {

    //MARK: - Private static funcs
    /// внутренняя функция структуры для удобного сравнения в других функциях структуры
    static func compare(_ first: Int?, with second: Int?) -> Bool {
        guard let first = first,
              let second = second else {
                  return false
              }
        if first == second {
            return true
        } else {
            return false
        }
    }
    /// Проверяет выбранное значение в переданных компонентах на соблюдение ограничений
    /// Изменяет значение в компонентах, если оно не соблюдает ограничения и возвращает true, если компоненты валидны в совокупности
    static func check(_ component: Components, in dateComponents: inout DateComponents) -> Bool {
        switch component {
        case .year:
            if let year = dateComponents.year {
                if year < 1 {
                    dateComponents.year = 1
                }
            }
        case .month:
            if let month = dateComponents.month {
                if month < 1 {
                    dateComponents.month = 1
                } else if month > 12 {
                    dateComponents.month = 12
                }
            }
        case .day:
            if let day = dateComponents.day {
                if day < 1 {
                    dateComponents.day = 1
                } else {
                    if day > 31 {
                        dateComponents.day = 31 // сокращаем цикл
                    }
                    while dateComponents.isValidDate == false {
                        guard let originDay = dateComponents.day else { break }
                        dateComponents.day = originDay - 1
                    }
                }
            }
        case .hour:
            if let hour = dateComponents.hour {
                if hour < 0 {
                    dateComponents.hour = 0
                } else if hour > 23 {
                    dateComponents.hour = 23
                }
            }
        case .min:
            if let min = dateComponents.minute {
                if min < 0 {
                    dateComponents.minute = 0
                } else if min > 59 {
                    dateComponents.minute = 59
                }
            }
        case .sec:
            if let sec = dateComponents.second {
                if sec < 0 {
                    dateComponents.second = 0
                } else if sec > 59 {
                    dateComponents.second = 59
                }
            }
        case .miliSec:
            if let nanoSec = dateComponents.nanosecond {
                if nanoSec < 0 {
                    dateComponents.nanosecond = 0
                } else if nanoSec > 999 {
                    dateComponents.nanosecond = 999 // на всякий случай
                }
            }
        }
        // проверка на валидность всех компонентов в совокупности
        if dateComponents.isValidDate {
            return true
        } else {
            return false
        }
    }

    static func validate(components: DateComponents) -> DateComponents {
        // базовая проверка на валидность
        guard components.isValidDate == false else {
            return components
        }
        // копися компонентов для возможности ихменения
        var newComponents = components
        // итеративная проверка каждого компонента
        // каждую итерацию также проверяется на валидность всех компонентов в совокупности
        for component in Components.allCases {
            if check(component, in: &newComponents) {
                return newComponents
            }
        }
        // возвращение измененных компонентов, но с невалидной датой
        return newComponents
    }
}
