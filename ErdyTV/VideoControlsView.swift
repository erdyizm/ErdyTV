import SwiftUI

struct VideoControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                // Timeline
                if !viewModel.isLive {
                    VStack(spacing: 4) {
                        Slider(value: Binding(
                            get: { viewModel.currentTime },
                            set: { viewModel.seek(to: $0) }
                        ), in: 0...max(viewModel.duration, 1))
                            .tint(.white)
                        
                        HStack {
                            Text(formatTime(viewModel.currentTime))
                                .font(.caption)
                                .monospacedDigit()
                            
                            Spacer()
                            
                            Text(formatTime(viewModel.duration))
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                }
                
                // Controls
                HStack(spacing: 40) {
                    if !viewModel.isLive {
                        Button {
                            viewModel.skipBackward()
                        } label: {
                            Image(systemName: "gobackward.30")
                                .font(.title)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.plain)
                    
                    if !viewModel.isLive {
                        Button {
                            viewModel.skipForward()
                        } label: {
                            Image(systemName: "goforward.30")
                                .font(.title)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(16)
            .padding(.bottom, 40)
            .padding(.horizontal, 60)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00"
    }
}
