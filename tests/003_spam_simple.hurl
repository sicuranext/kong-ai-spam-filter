POST http://localhost:8000/
Host: regression-test
Content-Type: application/x-www-form-urlencoded
`message=hello, I'm interested in your product. Please send me more information.`
HTTP 200
[Asserts]
jsonpath "$['form']['message']" == "hello, I'm interested in your product. Please send me more information."




POST http://localhost:8000/
Host: regression-test
Content-Type: application/x-www-form-urlencoded
`message=hello, are you interested in training at low costs? Visit our website traninglowcost dot com.`
HTTP 403
[Asserts]
jsonpath "$['message']" == "Request blocked due to spam detection"




POST http://localhost:8000/
Host: regression-test
Content-Type: application/form-data; boundary=xxx
```
--xxx
Content-Disposition: form-data; name="message"
Content-Type: text/plain

Un regalo per i tuoi pensieri...

Basta rispondere a qualche domanda

Vinci un Nuovo Marchio
Set Tupperware Modular Mates da 36 pezzi

🌟 Valutato 4,6 su 5 stelle (4.093 recensioni)
Sei stato scelto per partecipare al nostro Programma Fedeltà GRATIS!

Ti ci vorrà solo un minuto per ricevere questo fantastico premio.
--xxx--
```
HTTP 403
[Asserts]
jsonpath "$['message']" == "Request blocked due to spam detection"



