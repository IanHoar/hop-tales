import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI

extension Settings {
  @CasePathable
  public enum Cloud {
    case accountResolved(CloudSync.Account)
    case copyDeleted(Bool)
    case deleteConfirmed
    case deleteTapped
    case toggled(Bool)
  }
}

struct CloudRow: View {
  @Bindable var store: StoreOf<Settings>

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Toggle(
        isOn: Binding(get: { store.cloudSync }, set: { store.send(.cloud(.toggled($0))) })
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Use Hop Tales with iCloud")
            .font(Typography.display(20))
            .foregroundStyle(Paper.ink)
          Text(
            "Keeps progress safe on a new device and in step across your iPhone and iPad. It's "
              + "stored in your own iCloud. We never see it."
          )
          .font(Typography.ui(15))
          .foregroundStyle(Paper.muted)
        }
      }
      .tint(Paper.sageDeep)
      if let note {
        Text(note)
          .font(Typography.ui(14, weight: .medium))
          .foregroundStyle(Paper.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
      Button("Delete saved progress from iCloud", systemImage: "icloud.slash") {
        store.send(.cloud(.deleteTapped))
      }
      .buttonStyle(.paperChip)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .settingsField()
    .confirmationDialog(
      "Delete saved progress from iCloud?",
      isPresented: $store.isConfirmingCloudDelete,
      titleVisibility: .visible
    ) {
      Button("Delete from iCloud", role: .destructive) { store.send(.cloud(.deleteConfirmed)) }
    } message: {
      Text(
        "Progress stays on this device and saving to iCloud turns off. Other iPhones and iPads "
          + "saving to this iCloud account will clear their progress too."
      )
    }
  }

  private var note: String? {
    switch store.cloudNote {
    case .deleted: return "Deleted from iCloud. This device still has its progress."
    case .deleteFailed: return "Couldn't reach iCloud. Try again when you're online."
    case nil: break
    }
    guard store.cloudAccount == .signedOut else { return nil }
    return "This device isn't signed in to iCloud. Sign in from the Settings app to save progress."
  }
}
