* [Terraform - IaC in Cloud Resume Project ](#terraform---iac-in-cloud-resume-project)<br>
  * [Built Azure Infrastructure with Terraform](#built-azure-infrastructure-with-terraform)<br>
    * [Know what are required for the resources ](#know-what-are-required-for-the-resources)<br>
    * [Store tfstate in remote storage](#store-tfstate-in-remote-storage)<br>
    * [Pay attention to duplicate resources](#pay-attention-to-duplicate-resources)<br>
    * [Where to find your desired resource state](#where-to-find-your-desired-resource-state)<br>
    * [Know what are returned after a resource is created](#know-what-are-returned-after-a-resource-is-created)<br>
    * [CORS: allow all origins](#cors:-allow-all-origins)<br>
    * [Store connction string for the CosmoDB](#store-connction-string-for-the-cosmodb)<br>
    * [Integrate Function app with GitHub repository](#integrate-function-app-with-github-repository)<br>
    * [Data block report error when dry run](#data-block-report-error-when-dry-run)<br>
  * [Where to Improve](#where-to-improve)<br>
    * [Store the secrets in GitHub Secrets or Azure Key Vault](#store-the-secrets-in-github-secrets-or-azure-key-vault)<br>
    * [Create Logic App API conncetion using Terraform](#create-logic-app-api-conncetion-using-terraform)<br>
  * [Useful Links](#useful-links)<br>
    * [The use of `azurerm` provider](#the-use-of-`azurerm`-provider)<br>
    * [The setting of the Alert HTTP trigger](#the-setting-of-the-alert-http-trigger)<br>
---
# Terraform - IaC in Cloud Resume Project 

For the resume project, I decided to use Terraform as IaC tool. It took me a whole week to write it from scratch. I am sooo happy I did it eventually! I found the key is you must do it manually first and then you automate it using Terraform. If you are new to Terraform, I strongly recommend you create functional resources manually before you get into it. 

Now I will share some tips building the resume project infrastructure using Terraform, plus where to improve next. 

## Built Azure Infrastructure with Terraform
### Know what are required for the resources 
If you want to communicate with external services like Azure, AWS, or other cloud providers, you must use the API they provide for Terraform. That is what `required_providers` is for. It tells Terraform that you want to talk to the corresponding service, please download the right API. 

I used Azure, whose provider is `azurerm` (btw, former Azure PowerShell (PS for Azure) use the prefix `*-AzureRM*` for command as well, but now it uses `*-Az*`.). Then I listed all the resources I need, checked them one by one in the documentation to find the proper configuration examples ([Azurerm Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.14.0/docs)), and modify them to meet my requirements. That is basically how I write the terraform files for this project. 

### Store tfstate in remote storage
If the tfstate was accidentally deleted, which could be very likely to happen,  I could no longer manage the resources through Terraform. If I run `terraform plan` or `terraform apply`, it may lead to duplicate resources from scratch. I need to store `.tfstate` in remote. Therefore, I decided to store the Terraform state in Azure Storage ([Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)). I created a seperate resource group and a seperate storage account to store the terraform state. This is to isolate the configuration and the deployment of infrastructure. I could modify the infrastructure without affecting the configuration resource group or storage account accidentally.

### Pay attention to duplicate resources
Terraform identifies resources not only by their attributes (e.g., `name`) but also by their resource type (e.g., `azurerm_resource_group`) and their resource name in the configuration file. These together form a unique resource address (e.g., `azurerm_resource_group.frontend_rg` and `azurerm_resource_group.backend_rg`).

Therefore, if you use the same name for Azure resources, but name them differently in Terraform, terraform will treat them as different resources. And thus Terraform will attempt to create two separate resource groups with the same name, which is not allowed in Azure so it will fail. 

For example: the configuration below is not right in terraform files. Although the name and location are the same, their resource name are different, Terraform will treat them as two resources. And that is why I emphasize know what resources you are going to create. Do not just copy and paste the template from documentation.

```hcl
resource "azurerm_resource_group" "monitorrg" {
  name     = var.backend_rg
  location = var.location
}

resource "azurerm_resource_group" "functionrg" {
  name     = var.backend_rg
  location = var.location
}
```
### Where to find your desired resource state
Sometimes you need to set the desired state of resources in Terraform configuration files, but you don't know what the state should be or what configuration you need to write for the resources.

Under such circumstances, I find two ways to get what I need for the configuration. could check the json view of the resources you created manually. On the blade of the target resource, you could find the JSON view button on the right top corner. Click it and then you will know the state and configuration of the resources. You could translate the JSON into HCL format. 

For example, I leverage this method when I create alert rule. I look for criteria and put them in the Terraform config. Please note that some configurations are not available in `azurerm` provider. For example, the `criteriaType` has `StaticThresholdCriterion`, but it is static by default in `azurerm` provider.
```JSON
// resource JSON view on Portal.
"criteria": {
            "allOf": [
                {
                    "threshold": 20,
                    "name": "Metric1",
                    "metricNamespace": "Microsoft.Web/sites",
                    "metricName": "FunctionExecutionCount",
                    "operator": "GreaterThan",
                    "timeAggregation": "Total",
                    "skipMetricValidation": false,
                    "criterionType": "StaticThresholdCriterion"
                }
            ],
            "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria"
        },
```
```hcl
// alerts.tf:
  criteria {
      threshold = 20
      metric_namespace = "Microsoft.Web/sites"
      metric_name = "FunctionExecutionCount"
      operator = "GreaterThan"
      aggregation = "Total"
      skip_metric_validation = false
  }
```

### Know what are returned after a resource is created
When I was writing configureation for the action group that will receive and deliver the alert from monitored function app. I used a logic app receiver, which requires a callback_url attribuite. I cannot find much information for it. I know it is the http url for this trigger, but I could not retrieve it through a data block. It returned an error: `This object has no argument, nested block, or exported attribute named "trigger_url".`

I re-read the document([azurerm_logic_app_trigger_http_request - Attributes Reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_trigger_http_request#attributes-reference)) and found the following information:

<blockquote>
In addition to the Arguments listed above - the following Attributes are exported:

id - The ID of the HTTP Request Trigger within the Logic App Workflow.

callback_url - The URL of the Trigger within the Logic App Workflow. For use with certain resources like monitor_action_group and security_center_automation.
</blockquote>

So I could use the `callback_url` directly without any additional actions. It is very important to know what will return in the creation of resources.

### CORS: allow all origins
In the http trigger of the function app, we need to allow all origins. That is the CORS policy. We have two resolutions for this, one is to add allow all origins in the header of http response, another is to allow all origins in the settings of the funcion app. 

To allow all origins in the function app, we know how to do it in Portal. But now we need to add the setting in Terraform. 

According to [azurerm_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/function_app#cors-1). We need to add a block `site_config` to include the `cors` block.  
```hcl
A cors block supports the following:

allowed_origins - (Required) A list of origins which should be able to make cross-origin calls. * can be used to allow all calls.

support_credentials - (Optional) Are credentials supported?
```
### Store connction string for the CosmoDB
I store the connection string in the `environment variables`, which is not quite a good idea but for now I did not have a better solution (I think I could store it in the Key Vault but I haven't find the way to realize this method). 

To add an environment variable in the function app when creation, I need to put an `app_setting` block, which is a key-value pair you can customize. [azurerm_linux_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app#app_settings-1)

### Integrate Function app with GitHub repository
In resource `azurerm_function_app`, there is a `source_control` block to integrate the function with external repositories. However, this resource has been deprecated and removed in version 4.0+. I could only use resource `azurerm_linux_function_app` instead, BUT the problem is that `source_control` block is no longer available!!! We could only set the source control integration manually! 

This issue was reported in 2022 in the discussion [Support for azurerm_linux_function_app to add Source Control #18032](https://github.com/hashicorp/terraform-provider-azurerm/issues/18032) but still NOT resolved yet. I hope they could support this feature in a near future.

### Data block report error when dry run
When I dry run/`terraform plan`, I got the error saying resource does not exist. And then I realized that data will still connect to the subscription and fetch the resource information. I want to access the data of the resource that I did not really create but the resources I want to create. In such a case, I should use the attributes returned from the creation of the resources. 

For example, the `callback_url` I used in the former topic [know-what-are-returned-after-a-resource-is-created](#know-what-are-returned-after-a-resource-is-created).

## Where to Improve
### Store the secrets in GitHub Secrets or Azure Key Vault

I have secrets like CosmoDB connection string  and Azure Credentials. I store the Azure credentials in GitHub secrets and the connection string in environment variables in the pipeline host. If I want to make the connection string more secure, I could store it in Azure Key Vault: [Set and retrieve a secret from Azure Key Vault using Azure CLI](https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli)

No matter where you store the secrets, it is more secure than just export the connection string during the pipeline. 

### Create Logic App API conncetion using Terraform
When I create the action `Send Email via Outlook` for the logic app after it is triggered, I found it quite challenging to create the API connection through Terraform. According to [azurerm_api_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_connection), I must access the data of an existing managed API for an API connection. However, this managed API should be created under the Azure API Management service, which is quite expensive for me. Besides, since I could only create a simple API connection on Portal, why do I have to create an extra resource with Terraform? I really don't think this is a good idea.

While I was looking for solutions to this problem, I have found this module [fdmsantos/api-connections](https://registry.terraform.io/modules/fdmsantos/api-connections/azurerm/latest). It is the Office 365 API connection, and I think it is inspiring. But I did not have Office 365 so I didnot have a try. 

Therefore, to workaround the problem, I manually created the API connection on Portal and decided to use it in Terraform. I wrote the body of the API connection resource aaccording to code view of the manually-created logic app. 


## Useful Links
### The use of `azurerm` provider
[Azurerm Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.14.0/docs)\
[Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)\
[Backend block configuration overview](https://developer.hashicorp.com/terraform/language/backend)

### The setting of the Alert HTTP trigger
[Sample Alert Payload](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-payload-samples#sample-alert-payload)\
[azurerm_logic_app_trigger_http_request - Attributes Reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_trigger_http_request#attributes-reference)\
[Supported metrics with Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/metrics-index)\
[How to deploy Azure API Connection through Terraform with the status 'connected'](https://stackoverflow.com/questions/75692406/how-to-deploy-azure-api-connection-through-terraform-with-the-status-connected)