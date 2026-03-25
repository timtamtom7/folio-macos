import SwiftUI

struct ReaderSettingsView: View {
    @EnvironmentObject var viewModel: ReaderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Reading Width")
                    .font(.headline)
                Picker("Width", selection: $viewModel.readerWidth) {
                    ForEach(ReaderViewModel.ReaderWidth.allCases, id: \.self) { width in
                        Text(width.rawValue).tag(width)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            Group {
                Text("Font")
                    .font(.headline)
                Picker("Font", selection: $viewModel.readerFont) {
                    ForEach(ReaderViewModel.ReaderFont.allCases, id: \.self) { font in
                        Text(font.rawValue).tag(font)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Size:")
                    Slider(value: Binding(
                        get: { Double(viewModel.readerFontSize) },
                        set: { viewModel.readerFontSize = Int($0) }
                    ), in: 12...24, step: 1)
                    Text("\(viewModel.readerFontSize)pt")
                        .frame(width: 40)
                }
            }

            Divider()

            Group {
                Text("Theme")
                    .font(.headline)
                Picker("Theme", selection: $viewModel.readerTheme) {
                    ForEach(ReaderViewModel.ReaderTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Spacer()
        }
        .padding()
        .frame(width: 300)
        .onChange(of: viewModel.readerWidth) { _ in viewModel.save() }
        .onChange(of: viewModel.readerFont) { _ in viewModel.save() }
        .onChange(of: viewModel.readerFontSize) { _ in viewModel.save() }
        .onChange(of: viewModel.readerTheme) { _ in viewModel.save() }
    }
}

struct ReaderSettingsPopover: View {
    @EnvironmentObject var viewModel: ReaderViewModel

    var body: some View {
        ReaderSettingsView()
    }
}
