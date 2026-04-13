#!/bin/bash

# Reusable Terraform Wrapper Script
# Usage: ./deploy.sh [action] [environment] [project_dir]
# Example: ./deploy.sh apply prod ./my-vpc-project

# Fail on any error
set -e

ACTION=${1:-plan}
ENV=${2:-dev}
PROJECT_DIR=${3:-.}

# Colors for output readability
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Directory '$PROJECT_DIR' does not exist!${NC}"
    exit 1
fi

echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}   🚀 Terraform Automation Script  ${NC}"
echo -e "${CYAN}==============================================${NC}"
echo -e "Action    : ${YELLOW}$ACTION${NC}"
echo -e "Env Var   : ${YELLOW}${ENV}.tfvars${NC}"
echo -e "Directory : ${YELLOW}$(readlink -f "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")${NC}"

cd "$PROJECT_DIR"

# 1. Initialize
echo -e "\n${GREEN}[1/3] Initializing Terraform...${NC}"
terraform init -upgrade=false

# 2. Validation
echo -e "\n${GREEN}[2/3] Validating Configuration...${NC}"
if ! terraform fmt -check; then
    echo -e "${YELLOW}Notice: Some code formatting fixes are recommended. Run 'terraform fmt' to fix.${NC}"
fi
terraform validate

# Determine if a variables file exists for this environment
VAR_FLAG=""
if [ -f "${ENV}.tfvars" ]; then
    echo -e "${GREEN}Found variables file: ${ENV}.tfvars${NC}"
    VAR_FLAG="-var-file=${ENV}.tfvars"
else
    echo -e "${YELLOW}No variables file found: ${ENV}.tfvars (Proceeding without it)${NC}"
fi

# 3. Execution
echo -e "\n${GREEN}[3/3] Executing Action: ${ACTION^^}...${NC}"

case "$ACTION" in
    plan)
        terraform plan $VAR_FLAG -out="tfplan-${ENV}"
        echo -e "\n${CYAN}Plan saved as 'tfplan-${ENV}'. Run './deploy.sh apply $ENV $PROJECT_DIR' to deploy.${NC}"
        ;;
    
    apply)
        # Create a fresh plan
        terraform plan $VAR_FLAG -out="tfplan-${ENV}"
        echo -e "\n${YELLOW}Applying Plan...${NC}"
        # Apply the exact plan without prompting again
        terraform apply "tfplan-${ENV}"
        
        # Cleanup plan file once successfully applied
        rm -f "tfplan-${ENV}"
        echo -e "\n${GREEN}Deployment Completed Successfully!${NC}"
        ;;
    
    destroy)
        echo -e "${RED}WARNING: You are about to DESTROY infrastructure.${NC}"
        read -p "Are you sure? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            terraform destroy $VAR_FLAG -auto-approve
            echo -e "\n${GREEN}Destroy Completed Successfully!${NC}"
        else
            echo -e "${YELLOW}Destroy canceled.${NC}"
            exit 0
        fi
        ;;
        
    init-only)
        echo -e "${GREEN}Initialized purely.${NC}"
        ;;
        
    *)
        echo -e "${RED}Invalid action: $ACTION.${NC}"
        echo -e "Valid options: plan, apply, destroy, init-only"
        exit 1
        ;;
esac
