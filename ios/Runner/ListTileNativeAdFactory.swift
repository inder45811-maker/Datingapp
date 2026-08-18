import google_mobile_ads
import UIKit

class ListTileNativeAdFactory: FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: GADNativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> GADNativeAdView? {
    let nibView = Bundle.main.loadNibNamed("ListTileNativeAdView", owner: nil, options: nil)?.first
    guard let nativeAdView = nibView as? GADNativeAdView else {
      return makeProgrammaticAdView(nativeAd)
    }

    (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
    nativeAdView.nativeAd = nativeAd
    return nativeAdView
  }

  private func makeProgrammaticAdView(_ nativeAd: GADNativeAd) -> GADNativeAdView {
    let adView = GADNativeAdView(frame: .zero)
    adView.backgroundColor = UIColor(red: 0.086, green: 0.086, blue: 0.122, alpha: 1)

    let headline = UILabel()
    headline.text = nativeAd.headline
    headline.textColor = .white
    headline.font = UIFont.boldSystemFont(ofSize: 16)
    headline.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(headline)
    adView.headlineView = headline

    NSLayoutConstraint.activate([
      headline.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
      headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
      headline.topAnchor.constraint(equalTo: adView.topAnchor, constant: 16),
      headline.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -16),
    ])

    adView.nativeAd = nativeAd
    return adView
  }
}
