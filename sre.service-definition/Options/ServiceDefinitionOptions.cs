namespace sre.service_definition.options
{
	public class ServiceDefinitionOptions
	{
		public const string Section = "Sd";

		public Egress[] Egress { get; set; }

		public bool UseHttps { get; set; }

		public string Type { get; set; }

		public int Port { get; set; }

		public string CronSchedule { get; set; }
	}
}
