import UIKit

class DigitalFrontDetailsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let faceImageView = UIImageView()
    private let ocrDataStackView = UIStackView()
    private let uploadBackButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGradientBackground()
        displayData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)

        // ✅ Scroll View Setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // ✅ Title Label
        titleLabel.text = "ID Front Verification Results"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // ✅ Face Image View (Cropped Face)
        faceImageView.contentMode = .scaleAspectFill
        faceImageView.layer.cornerRadius = 50 // Circular Image
        faceImageView.layer.masksToBounds = true
        faceImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(faceImageView)

        // ✅ OCR Data Stack View
        ocrDataStackView.axis = .vertical
        ocrDataStackView.spacing = 10
        ocrDataStackView.alignment = .fill
        ocrDataStackView.translatesAutoresizingMaskIntoConstraints = false

        let ocrContainer = UIView()
        ocrContainer.backgroundColor = .white
        ocrContainer.layer.cornerRadius = 10
        ocrContainer.translatesAutoresizingMaskIntoConstraints = false
        ocrContainer.addSubview(ocrDataStackView)
        contentView.addSubview(ocrContainer)

        // ✅ Upload Back Button
        uploadBackButton.setTitle("Upload ID Back", for: .normal)
        uploadBackButton.backgroundColor = .blue
        uploadBackButton.setTitleColor(.white, for: .normal)
        uploadBackButton.layer.cornerRadius = 10
        uploadBackButton.translatesAutoresizingMaskIntoConstraints = false
        uploadBackButton.addTarget(self, action: #selector(uploadIdBackTapped), for: .touchUpInside)
        view.addSubview(uploadBackButton)

        // ✅ Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            faceImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            faceImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            faceImageView.widthAnchor.constraint(equalToConstant: 100),
            faceImageView.heightAnchor.constraint(equalToConstant: 100),

            ocrContainer.topAnchor.constraint(equalTo: faceImageView.bottomAnchor, constant: 20),
            ocrContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ocrContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            ocrDataStackView.topAnchor.constraint(equalTo: ocrContainer.topAnchor, constant: 10),
            ocrDataStackView.leadingAnchor.constraint(equalTo: ocrContainer.leadingAnchor, constant: 10),
            ocrDataStackView.trailingAnchor.constraint(equalTo: ocrContainer.trailingAnchor, constant: -10),
            ocrDataStackView.bottomAnchor.constraint(equalTo: ocrContainer.bottomAnchor, constant: -10),

            uploadBackButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            uploadBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadBackButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            uploadBackButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func displayData() {
        let sharedVM = SharedViewModel.shared

        // ✅ Load Cropped Face Image
        if let faceUrl = URL(string: sharedVM.ocrResponse?.imageUrl ?? "") {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: faceUrl), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.faceImageView.image = image
                        sharedVM.faceCropped = image
                    }
                }
            }
        }

        // ✅ Load OCR Data
        if let frontData = sharedVM.ocrResponse {
            addInfoLabel(to: ocrDataStackView, title: "Full Name", value: frontData.fullName)
            addInfoLabel(to: ocrDataStackView, title: "Date of Birth", value: frontData.dob)
            addInfoLabel(to: ocrDataStackView, title: "Sex", value: frontData.sex)
            addInfoLabel(to: ocrDataStackView, title: "Nationality", value: frontData.nationality)
            addInfoLabel(to: ocrDataStackView, title: "FCN", value: frontData.fcn)
            addInfoLabel(to: ocrDataStackView, title: "Date of Expiry", value: frontData.dateOfExpiry)
        }
    }

    private func addInfoLabel(to stackView: UIStackView, title: String, value: String) {
        let label = UILabel()
        label.text = "\(title): \(value)"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        stackView.addArrangedSubview(label)
    }

    @objc private func uploadIdBackTapped() {
        let uploadBackId = UploadBackDigitalIDViewController()
        uploadBackId.modalPresentationStyle = .fullScreen

        if let topVC = getTopViewController(), topVC.view.window != nil {
            topVC.present(uploadBackId, animated: true, completion: {
            print("✅ Successfully presented DigitalFrontDetailsViewController")
        })
        } else {
           print("❌ Unable to find a valid top view controller to present.")
        }
    }
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: "#60CFFF").cgColor,
            UIColor(hex: "#C5EEFF").cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func getTopViewController(_ rootViewController: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    .first?.rootViewController) -> UIViewController? {
    
    if let presentedViewController = rootViewController?.presentedViewController {
        return getTopViewController(presentedViewController)
    }
    if let navigationController = rootViewController as? UINavigationController {
        return getTopViewController(navigationController.visibleViewController)
    }
    if let tabBarController = rootViewController as? UITabBarController {
        return getTopViewController(tabBarController.selectedViewController)
    }
    return rootViewController
}

}
