import SwiftUI
import PassKit

struct ContentView: View {
    @State private var statusMessage = ""
    @State private var showAddPass = false
    @State private var passToAdd: PKPass?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "airplane")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Wallet Pass Demo")
                    .font(.title2.bold())

                VStack(spacing: 16) {
                    Button {
                        createBoardingPass()
                    } label: {
                        Label("Create Boarding Pass", systemImage: "plus.rectangle.on.folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        updateBoardingPass()
                    } label: {
                        Label("Update Boarding Pass", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button {
                        viewBoardingPass()
                    } label: {
                        Label("View Boarding Pass", systemImage: "wallet.pass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal, 32)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .sheet(isPresented: $showAddPass) {
                if let pass = passToAdd {
                    AddPassView(pass: pass)
                }
            }
        }
    }

    private func createBoardingPass() {
        guard let url = Bundle.main.url(forResource: "BoardingPass", withExtension: "pkpass"),
              let data = try? Data(contentsOf: url),
              let pass = try? PKPass(data: data) else {
            statusMessage = "Failed to load BoardingPass.pkpass from bundle"
            return
        }

        let library = PKPassLibrary()
        if library.containsPass(pass) {
            statusMessage = "This boarding pass is already in your Wallet"
            return
        }

        passToAdd = pass
        showAddPass = true
        statusMessage = "Presenting add-pass dialog..."
    }

    private func updateBoardingPass() {
        let library = PKPassLibrary()
        let existingPasses = library.passes(of: .barcode)

        guard let existingPass = existingPasses.first(where: {
            $0.passTypeIdentifier == "pass.com.example.WalletPassDemoApp" &&
            $0.serialNumber == "DEMO-BP-001"
        }) else {
            statusMessage = "No matching boarding pass found. Create one first."
            return
        }

        // Pick a random variant (1-10)
        let variantIndex = Int.random(in: 1...10)
        guard let url = Bundle.main.url(forResource: "Variant\(variantIndex)", withExtension: "pkpass"),
              let data = try? Data(contentsOf: url),
              let updatedPass = try? PKPass(data: data) else {
            statusMessage = "Failed to load Variant\(variantIndex).pkpass"
            return
        }

        // Silently replace: replacePass works when the pass is still in Wallet
        library.replacePass(with: updatedPass)
        statusMessage = "Pass updated (variant \(variantIndex))! Check Wallet."
    }

    private func viewBoardingPass() {
        let library = PKPassLibrary()
        let passes = library.passes(of: .barcode)

        let match = passes.first {
            $0.passTypeIdentifier == "pass.com.example.WalletPassDemoApp" &&
            $0.serialNumber == "DEMO-BP-001"
        }

        guard let pass = match else {
            statusMessage = "No boarding pass found in Wallet (\(passes.count) passes scanned). Create one first."
            return
        }

        // Open the pass in Wallet using its URL
        if let passURL = pass.passURL {
            UIApplication.shared.open(passURL)
            statusMessage = "Opening pass in Wallet..."
        } else {
            statusMessage = "Could not get pass URL"
        }
    }
}

struct AddPassView: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        PKAddPassesViewController(pass: pass)!
    }

    func updateUIViewController(_ uiViewController: PKAddPassesViewController, context: Context) {}
}
