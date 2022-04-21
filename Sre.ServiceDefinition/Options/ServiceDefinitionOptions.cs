namespace Sre.ServiceDefinition.Options
{
	using System;
	using System.Collections.Generic;

	public class ServiceDefinitionOptions
	{
		public const string Section = "Sd";

		public NetworkPolicy[] Egress { get; set; }

		public NetworkPolicy[] Ingress { get; set; }

		public Database[] Databases { get; set; }

		public bool UseHttps { get; set; }

		public string Type { get; set; }

		public int Port { get; set; }

		public string CronSchedule { get; set; }

		public string Description { get; set; }

		public string CertificateHash { get; set; }

		public string RunUnderAccount { get; set; }

		[Obsolete("This field is no longer used for its original intended purpose. If you need this information inside your own application you need to store and retrieve it some other way.")]
		public List<string> ApiRoutesToPublish { get; set; }

		[Obsolete("This field is no longer used for its original intended purpose. If you need this information inside your own application you need to store and retrieve it some other way.")]
		public List<string> RoutesToPublish { get; set; }

		public string Namespace { get; set; }

		public int RequestTimeout { get; set; }

		public int Replicas { get; set; }

		public bool Scaling { get; set; }

		public Resources Resources { get; set; }

		public List<string> InitContainers { get; set; }

		public bool GrantContainersAccessToSettings { get; set; }

		public string ServiceAccount { get; set; }

		public bool DisableRequestLogging { get; set; }

		public bool BypassAuthentication { get; set; }

		public string ExecutionBehaviour { get; set; }
    }
}
