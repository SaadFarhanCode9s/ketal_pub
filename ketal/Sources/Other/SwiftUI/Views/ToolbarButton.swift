//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ToolbarButton: View {
    enum Role {
        case cancel
        case done
        case save

        var title: String {
            switch self {
            case .cancel:
                L10n.actionCancel
            case .done:
                L10n.actionDone
            case .save:
                L10n.actionSave
            }
        }

        @ViewBuilder
        var icon: some View {
            switch self {
            case .cancel:
                CompoundIcon(\.close)
                    .foregroundStyle(.compound.iconPrimary)
            case .done, .save:
                CompoundIcon(\.check)
                    .foregroundStyle(.compound.iconOnSolidPrimary)
            }
        }

        var tint: Color {
            switch self {
            case .cancel:
                .compound.bgCanvasDefault
            case .done, .save:
                .compound.bgAccentRest
            }
        }
    }

    let role: Role
    let action: () -> Void

    var body: some View {
        Button(role.title, action: action)
    }
}

struct ToolbarButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            Color.clear
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        ToolbarButton(role: .done) { }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        ToolbarButton(role: .cancel) { }
                    }
                }
        }
    }
}
