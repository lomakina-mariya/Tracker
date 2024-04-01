import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewControllers = [setTrackersViewController(), setStatisticsViewController()]
    }

    func setTrackersViewController() -> UINavigationController {
        let trackersViewController = TrackersViewController()
        trackersViewController.tabBarItem.image = UIImage(named: "tab_trackers_active")
        return UINavigationController(rootViewController: trackersViewController)
    }

    func setStatisticsViewController() -> UINavigationController {
        let statisticsViewController = StatisticsViewController()
        statisticsViewController.tabBarItem.image = UIImage(named: "tab_statistics_not_active")
        return UINavigationController(rootViewController: statisticsViewController)
    }
    

}

