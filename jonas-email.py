from mail import Email

mail = Email(
    "smtp.gmail.com",
    587,
    "jannis.reufsteck1@gmail.com",
    "jonas.heck@abs-gmbh.de",
    "cijy tpmv wigq yplb",
)
mail.send_email(mail.create_email())
