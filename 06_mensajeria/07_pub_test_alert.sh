aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject "Alerta CPU Alta" \
  --message '{"servicio":"api-acme","tipo":"CPU_ALTA","valor":"85%","severidad":"alta","accion":"revisar escalabilidad"}'