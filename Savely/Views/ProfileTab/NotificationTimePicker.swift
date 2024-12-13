//
//  NotificationTimePicker.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import SwiftUI

struct NotificationTimePicker: View {
    var title: String
    @Binding var selectedTime: Date
    var onSave: (Date) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            DatePicker(
                Strings.Placeholders.selectTimePLaceholder,
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .frame(height: 200)

            Button(action: {
                onSave(selectedTime)
            }) {
                Text(Strings.Buttons.saveButton)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("primaryGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
            }
            .padding()
        }
        .padding()
        .background(Color("cardBackgroundColor"))
        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
        .shadow(radius: 5)
    }
}

struct NotificationTimePicker_Previews: PreviewProvider {
    static var previews: some View {
        NotificationTimePicker(
            title: "Select Reminder Time",
            selectedTime: .constant(Date())
        ) { _ in }
    }
}
