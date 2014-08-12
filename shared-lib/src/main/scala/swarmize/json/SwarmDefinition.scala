package swarmize.json

import org.joda.time.DateTime
import play.api.libs.json.{JsValue, Json}

case class SwarmDefinition
(
  name: String,
  description: String,

  fields: List[SwarmField],
  opens_at: Option[DateTime],
  closes_at: Option[DateTime]
) {
  def toJson = SwarmDefinition toJson this

}



case class SwarmField
(
  field_name: String,
  field_name_code: String,
  field_type: String,
  possible_values: Option[Map[String, String]],
  sample_value: Option[String],
  compulsory: Boolean
)

object SwarmDefinition {
  implicit val dateFormat = PlayJsonIsoDateFormat
  implicit val fieldJsonFormat = Json.format[SwarmField]
  implicit val definitionJsonFormat = Json.format[SwarmDefinition]

  def toJson(d: SwarmDefinition): JsValue = Json toJson d
}