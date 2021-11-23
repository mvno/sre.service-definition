namespace sre.service_definition.options
{
	public class NetworkPolicy
	{
		public string Service { get; set; }

		public string Namespace { get; set; }

		public string Port { get; set; }

		public string Protocol { get; set; }
	}
}
