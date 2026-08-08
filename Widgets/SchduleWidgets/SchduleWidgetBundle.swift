import SwiftUI
import WidgetKit

@main
struct SchduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthWidget()
        TodayWidget()
        BoardStackWidget()
        LockScreenWidget()
        QuickLogControl()
    }
}
