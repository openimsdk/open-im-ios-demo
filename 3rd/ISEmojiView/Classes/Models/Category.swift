






import Foundation

public enum Category: Equatable {
    case recents
    case smileysAndPeople
    case animalsAndNature
    case foodAndDrink
    case activity
    case travelAndPlaces
    case objects
    case symbols
    case flags
    case custom(String, String)
    case face
    
    static var count = 10
    
    var title: String {
        switch self {
        case .recents:
            return "Frequently Used"
        case .smileysAndPeople:
            return "Smileys & People"
        case .animalsAndNature:
            return "Animals & Nature"
        case .foodAndDrink:
            return "Food & Drink"
        case .activity:
            return "Activity"
        case .travelAndPlaces:
            return "Travel & Places"
        case .objects:
            return "Objects"
        case .symbols:
            return "Symbols"
        case .flags:
            return "Flags"
        case .custom(let title, _):
            return title
        case .face:
            return "Face"
        }
    }
    
    var iconName: String {
        switch self {
        case .recents:
            return "ic_recents"
        case .smileysAndPeople:
            return "ic_smileys_people"
        case .animalsAndNature:
            return "ic_animals_nature"
        case .foodAndDrink:
            return "ic_food_drink"
        case .activity:
            return "ic_activity"
        case .travelAndPlaces:
            return "ic_travel_places"
        case .objects:
            return "ic_objects"
        case .symbols:
            return "ic_symbols"
        case .flags:
            return "ic_flags"
        case .custom(_, let iconName):
            return iconName
        case .face:
            return "ic_ic_smileys_people"
        }
    }
}

public enum TabCategory: Equatable {
    case emoji
    case favorite
        
    var title: String {
        switch self {
        case .emoji:
            return "emoji"
        case .favorite:
            return "favorite"
        }
    }
    
    var iconName: String {
        switch self {
        case .emoji:
            return "ic_emoji_tab_normal"
        case .favorite:
            return "ic_favorite_tab_normal"
        }
    }
}
