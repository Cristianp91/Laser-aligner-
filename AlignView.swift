import SwiftUI

struct AlignView: View {
    @EnvironmentObject var session: AlignmentSession
    @State private var showFar = true
    @State private var suggestion: Suggestion = Suggestion(heading: "Inizia",
                                                           detail: "Scegli lo stage e segna i punti near/far.",
                                                           adjustments: [], isGood: false)
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Stage", selection: $session.stage) {
                    ForEach(Stage.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if session.stage == .nozzle {
                    Toggle("Mostra Far (non necessario per nozzle)", isOn: $showFar)
                        .padding(.horizontal)
                        .disabled(true)
                } else {
                    Toggle("Usa Near/Far", isOn: $showFar)
                        .padding(.horizontal)
                }

                MirrorBoardView(near: $session.board.near,
                                far: $session.board.far,
                                target: $session.board.target,
                                showFar: showFar && session.stage != .nozzle)

                Button {
                    recalc()
                } label: {
                    Label("Calcola suggerimento", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                SuggestionView(suggestion: suggestion)

                HStack {
                    Button(role: .destructive) {
                        session.board = TestPoints()
                        suggestion = Suggestion(heading: "Azzerato", detail: "Segna di nuovo i punti.", adjustments: [], isGood: false)
                    } label: {
                        Label("Reset", systemImage: "trash")
                    }
                    Spacer()
                    Button {
                        // quick ok check
                        recalc()
                        if suggestion.isGood { Haptics.success() } else { Haptics.warning() }
                    } label: {
                        Label("Verifica", systemImage: "checkmark.seal")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Allineamento")
        }
    }

    private func recalc() {
        let mounts = (m1: session.mountM1, m2: session.mountM2, m3: session.mountM3)
        suggestion = AlignmentEngine.suggest(stage: session.stage, board: session.board, mounts: mounts, tolerance: session.tolerance)
    }
}

struct SuggestionView: View {
    var suggestion: Suggestion
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestion.isGood ? "checkmark.circle.fill" : "lightbulb.max")
                Text(suggestion.heading).font(.headline)
            }
            Text(suggestion.detail)
            if !suggestion.adjustments.isEmpty {
                Divider().padding(.vertical, 4)
                ForEach(suggestion.adjustments) { adj in
                    HStack {
                        Text(adj.screwName)
                        Spacer()
                        let sign = adj.microTurns >= 0 ? "↻ CW" : "↺ CCW"
                        Text(String(format: "%.1f", abs(adj.microTurns)) + " × micro‑giri " + sign)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }
}
