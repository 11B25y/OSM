import SwiftUI

struct ErrorAlertView: ViewModifier {
    @Binding var errorMessage: String?
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    func errorAlert(errorMessage: Binding<String?>) -> some View {
        self.modifier(ErrorAlertView(errorMessage: errorMessage))
    }
}
