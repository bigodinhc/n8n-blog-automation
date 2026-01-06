# 💻 IMPLEMENTAÇÃO TÉCNICA: AGENTS COM TOOLS PARA N8N

## Minerals Trading Daily - Production Ready Architecture

**Status:** Ready to build
**Framework:** n8n + LangChain + Supabase
**Timeline:** 6-8 weeks to MVP
**Complexity:** Advanced

---

## 1. TECH STACK RECOMENDADO

```
┌─────────────────────────────────────────────────┐
│ ORCHESTRATION LAYER                             │
├─────────────────────────────────────────────────┤
│ Primary: n8n (workflows) + LangChain (agents)  │
│ Alternative: Temporal (advanced workflows)      │
│ Memory: Redis (conversation state)              │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ LLM LAYER                                       │
├─────────────────────────────────────────────────┤
│ Orchestrator: Claude 3.5 Sonnet                │
│ Specialized Agents: GPT-4o, Claude 3 Opus      │
│ Fallback: Mixtral 8x7B (open source)           │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ DATA LAYER                                      │
├─────────────────────────────────────────────────┤
│ Vectors: Supabase (pgvector)                   │
│ Time-series: TimescaleDB                        │
│ Structured: PostgreSQL                          │
│ Graph: Neo4j (relationships)                    │
│ Cache: Redis (hot data)                         │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ TOOLS / EXTERNAL APIS                           │
├─────────────────────────────────────────────────┤
│ Web Scraping: Firecrawl API                    │
│ News: NewsAPI, Perplexity Search               │
│ Markets: Alpha Vantage, Trading View           │
│ Sentiment: Huggingface, TextBlob               │
│ Macro: Fred API, Trading Economics             │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ DEPLOYMENT                                      │
├─────────────────────────────────────────────────┤
│ Hosting: Railway / Render / AWS ECS             │
│ Monitoring: Datadog / New Relic                 │
│ Logging: DataDog / ELK Stack                    │
│ Queuing: Bull (Redis-based)                     │
└─────────────────────────────────────────────────┘
```

---

## 2. ARCHITECTURE DIAGRAM

```
USER INPUT
    ↓
┌─────────────────────────────────────┐
│ n8n Chat Trigger                    │
│ (Webhook endpoint)                  │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────┐
│ ORCHESTRATOR AGENT (Claude 3.5 Sonnet)          │
│                                                  │
│ Steps:                                           │
│ 1. Parse user query                             │
│ 2. Analyze complexity                           │
│ 3. Plan agent sequence                          │
│ 4. Determine which tools needed                 │
│ 5. Dispatch parallel/sequential tasks           │
│ 6. Monitor progress                             │
│ 7. Synthesize results                           │
│ 8. Format response                              │
└─────────────────────────────────────────────────┘
    ↓ DISPATCHES TO ↓
┌──────────────────┬──────────────────┬──────────────────┐
│ NEWS AGENT       │ FUNDAMENTAL AGENT│ MACRO AGENT      │
│ (GPT-4o)         │ (Claude 3 Opus)  │ (GPT-4o)         │
│                  │                  │                  │
│ Tools:           │ Tools:           │ Tools:           │
│ - Firecrawl      │ - TimescaleDB    │ - Fred API       │
│ - NewsAPI        │ - Production DB  │ - Trading Econ   │
│ - Sentiment      │ - Inventory DB   │ - Macro Indicators
│ - Fact Check     │ - Correlation    │ - Policy DB      │
└──────────────────┴──────────────────┴──────────────────┘
    ↓ MORE AGENTS ↓
┌──────────────────┬──────────────────┬──────────────────┐
│ TECHNICAL AGENT  │ SENTIMENT AGENT  │ RISK AGENT       │
│ (GPT-4o)         │ (Claude 3 Opus)  │ (GPT-4o)         │
│                  │                  │                  │
│ Tools:           │ Tools:           │ Tools:           │
│ - ChartData      │ - Social Media   │ - Risk Models    │
│ - Technical Lib  │ - Twitter API    │ - Scenario Test  │
│ - Indicators     │ - Bitmex Data    │ - VaR Calc       │
│ - Levels DB      │ - Sentiment API  │ - Stress Test    │
└──────────────────┴──────────────────┴──────────────────┘
    ↓ AGGREGATE ↓
┌─────────────────────────────────────────────────┐
│ CORRELATION AGENT + HISTORICAL AGENT            │
│                                                  │
│ - Correlates insights                           │
│ - Identifies contradictions                     │
│ - Finds historical parallels                    │
│ - Weights confidence                            │
└─────────────────────────────────────────────────┘
    ↓ FINAL SYNTHESIS ↓
┌─────────────────────────────────────────────────┐
│ ORCHESTRATOR FINAL PASS                         │
│                                                  │
│ - Combine all insights                          │
│ - Generate recommendations                      │
│ - Create scenarios (bull/base/bear)             │
│ - Format professional response                  │
│ - Add caveats and risks                         │
└─────────────────────────────────────────────────┘
    ↓
USER RESPONSE (Streaming)
```

---

## 3. N8N WORKFLOW SPECIFICATION

### Main Orchestrator Workflow

```yaml
name: "Minerals Trading Agent Orchestrator"
version: 1.0

triggers:
  - type: webhook_chat
    path: /chat/mineral-analysis
    method: POST

workflow:
  nodes:
    # Node 1: Chat Input Processing
    - id: "input_processor"
      type: "function"
      code: |
        return {
          query: $json.message,
          user_id: $json.user_id,
          context: $json.context,
          timestamp: new Date().toISOString()
        }

    # Node 2: Complexity Analysis
    - id: "complexity_analyzer"
      type: "llm"
      model: "claude-3.5-sonnet"
      prompt: |
        Analyze this query for complexity level:
        Query: {{ $json.query }}
        
        Output JSON:
        {
          "complexity": "simple|medium|complex",
          "required_agents": ["agent1", "agent2", ...],
          "execution_order": "parallel|sequential",
          "estimated_time": 5,
          "reasoning": "..."
        }

    # Node 3: Load Conversation Memory
    - id: "memory_loader"
      type: "redis"
      operation: "get"
      key: "conversation:{{ $json.user_id }}"
      ttl: 3600

    # Node 4: Parallel Agent Execution
    - id: "agent_dispatcher"
      type: "parallel"
      max_concurrent: 5
      
      branches:
        - name: "news_agent"
          workflow: "news_aggregator_agent"
          inputs:
            query: "{{ $json.query }}"
            memory: "{{ $json.conversation_history }}"
          timeout: 30
        
        - name: "fundamental_agent"
          workflow: "fundamental_analyzer_agent"
          inputs:
            query: "{{ $json.query }}"
            memory: "{{ $json.conversation_history }}"
          timeout: 30
        
        - name: "macro_agent"
          workflow: "macro_strategist_agent"
          inputs:
            query: "{{ $json.query }}"
            memory: "{{ $json.conversation_history }}"
          timeout: 30
        
        - name: "sentiment_agent"
          workflow: "sentiment_analyzer_agent"
          inputs:
            query: "{{ $json.query }}"
          timeout: 20
        
        - name: "technical_agent"
          workflow: "technical_analyst_agent"
          inputs:
            query: "{{ $json.query }}"
          timeout: 25

    # Node 5: Sequential Refinement Agents
    - id: "refinement_agents"
      type: "sequential"
      dependencies: ["agent_dispatcher"]
      
      steps:
        - name: "correlation_agent"
          workflow: "correlation_expert_agent"
          inputs:
            agent_results: "{{ $json.parallel_results }}"
            query: "{{ $json.query }}"
          timeout: 15
        
        - name: "historical_agent"
          workflow: "historical_context_agent"
          inputs:
            agent_results: "{{ $json.parallel_results }}"
            correlation_results: "{{ $json.correlation_results }}"
            query: "{{ $json.query }}"
          timeout: 20
        
        - name: "risk_agent"
          workflow: "risk_manager_agent"
          inputs:
            all_results: "{{ $json.all_agent_results }}"
            query: "{{ $json.query }}"
          timeout: 15

    # Node 6: Synthesis
    - id: "synthesizer"
      type: "llm"
      model: "gpt-4o"
      prompt: |
        You are synthesizing analysis from 8 expert agents.
        
        Agent Results:
        {{ JSON.stringify($json.all_results, null, 2) }}
        
        Original Query: {{ $json.query }}
        
        Create professional analysis with:
        1. ROOT CAUSE (with confidence score 0-100)
        2. SUPPORTING EVIDENCE (from agents)
        3. CONTRADICTIONS (if any)
        4. HISTORICAL PARALLELS
        5. SCENARIOS (bull/base/bear with probabilities)
        6. RECOMMENDATION (specific action)
        7. RISK WARNINGS
        8. REASONING TRANSPARENCY (show your work)
        
        Format as JSON for markdown rendering

    # Node 7: Markdown Formatter
    - id: "formatter"
      type: "function"
      code: |
        const analysis = $json.synthesis;
        return {
          markdown: formatAnalysis(analysis),
          json: analysis,
          confidence: analysis.root_cause.confidence
        }

    # Node 8: Update Conversation Memory
    - id: "memory_updater"
      type: "redis"
      operation: "set"
      key: "conversation:{{ $json.user_id }}"
      value: |
        {
          "messages": [...previous, { role: "assistant", content: "{{ $json.markdown }}" }],
          "last_updated": new Date().toISOString(),
          "agent_results_summary": "{{ $json.json }}"
        }
      ttl: 3600

    # Node 9: Stream Response
    - id: "response"
      type: "chat_output"
      stream: true
      content: "{{ $json.markdown }}"
      format: "markdown"

  error_handling:
    - condition: "any_agent_timeout"
      action: "use_cached_results"
    
    - condition: "conflicting_recommendations"
      action: "escalate_to_orchestrator_logic"
    
    - condition: "low_confidence"
      action: "add_disclaimer"

  monitoring:
    - metric: "execution_time"
      alert: "if > 45 seconds"
    
    - metric: "agent_success_rate"
      alert: "if < 85%"
    
    - metric: "confidence_score"
      alert: "if recommendation < 60%"
```

### Individual Agent Workflow (Example: News Agent)

```yaml
name: "news_aggregator_agent"
version: 1.0

inputs:
  query: string
  memory: array
  max_iterations: 5

workflow:
  agent:
    model: "gpt-4o"
    temperature: 0.7
    
    system_prompt: |
      You are a news aggregation expert for commodity markets.
      Your role: Find and analyze news related to the commodity query.
      
      Guidelines:
      - Search multiple news sources
      - Assess relevance to commodity markets
      - Extract key facts and drivers
      - Identify contradictions
      - Rate confidence 0-100
      - Return structured findings
      
      Use tools intelligently - don't call tools unnecessarily.
    
    tools:
      - name: "web_search"
        description: "Search news from 50+ financial sources"
        parameters:
          query:
            type: "string"
            description: "Search query for news"
          limit:
            type: "number"
            default: 10
        implementation: "firecrawl_api"
      
      - name: "sentiment_analysis"
        description: "Analyze sentiment of news articles"
        parameters:
          text:
            type: "string"
          language:
            type: "string"
            default: "en"
        implementation: "huggingface_model"
      
      - name: "fact_check"
        description: "Verify facts against multiple sources"
        parameters:
          claim:
            type: "string"
          context:
            type: "string"
        implementation: "custom_validation_engine"
      
      - name: "vdb_search"
        description: "Search document vector database"
        parameters:
          query:
            type: "string"
          top_k:
            type: "number"
            default: 5
        implementation: "supabase_pgvector"
    
    max_iterations: 5
    stop_when: "Agent decides task complete"

  post_processing:
    - structure_output:
        findings: "array[{article, relevance, sentiment, confidence}]"
        root_cause_indicators: "array[string]"
        overall_confidence: "number"
        sources: "array[string]"

  output_validation:
    - check: "all_findings_have_sources"
    - check: "confidence_scores_valid"
    - check: "no_hallucinations_detected"
```

---

## 4. DATABASE SCHEMA

### Supabase Setup

```sql
-- Conversation Memory
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  messages JSONB NOT NULL, -- Array of messages with roles
  agent_results JSONB, -- Cached agent outputs
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  ttl_hours INT DEFAULT 24
);

-- Agent Performance Metrics
CREATE TABLE agent_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_name TEXT NOT NULL,
  query_text TEXT,
  execution_time_ms INT,
  tool_calls INT,
  success BOOLEAN,
  confidence_score FLOAT,
  user_rating INT, -- 1-5
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Document Vectors (for VDB search)
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  source TEXT,
  metadata JSONB,
  embedding vector(1536), -- OpenAI embedding dimension
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create vector index
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops);

-- Tool Call Log
CREATE TABLE tool_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id TEXT,
  tool_name TEXT,
  parameters JSONB,
  result JSONB,
  status TEXT, -- success/failure
  duration_ms INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analysis History
CREATE TABLE analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT,
  query TEXT,
  analysis JSONB,
  recommendation TEXT,
  confidence_score FLOAT,
  agents_used TEXT[],
  execution_time_ms INT,
  cost_cents NUMERIC,
  feedback_rating INT, -- 1-5 from user
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. API SPECIFICATIONS

### Chat Endpoint

```
POST /api/chat/mineral-analysis

Request:
{
  "message": "Níquel caiu 5%, por quê?",
  "user_id": "user_123",
  "context": {
    "commodities": ["nickel"],
    "timeframe": "24h",
    "depth": "professional"
  }
}

Response (Streaming):
{
  "type": "stream",
  "content": "# ANÁLISE: Níquel -5%\n\n## Causa Raiz...",
  "metadata": {
    "confidence": 87,
    "agents_used": ["news", "fundamental", "macro", "risk"],
    "execution_time_ms": 2300,
    "cost_cents": 45
  }
}
```

### Feedback Endpoint

```
POST /api/feedback

Request:
{
  "analysis_id": "analysis_uuid",
  "rating": 4,
  "comment": "Very helpful, but missed China stimulus news"
}

Action:
- Store feedback in database
- Update agent fine-tuning data
- Retrain if pattern detected
```

---

## 6. OPTIMIZATION TECHNIQUES

### Token Efficiency

```python
# Strategy 1: Prompt Compression
def optimize_prompt(query, memory, tools):
    # Only include relevant context
    relevant_memory = filter_by_relevance(memory, query)
    relevant_tools = select_top_tools(tools, query)
    
    prompt = f"""
    Query: {query}
    
    Recent Context: {compress(relevant_memory)}
    
    Available Tools: {relevant_tools}
    
    Task: Analyze and respond.
    """
    return prompt

# Strategy 2: Caching Agent Outputs
def cache_agent_result(agent_name, query_hash, result):
    redis.setex(
        f"agent:{agent_name}:{query_hash}",
        ttl=3600,
        value=json.dumps(result)
    )

# Strategy 3: Tool Relevance Filtering
def select_tools_for_query(query):
    # Embed query
    query_vec = embed(query)
    
    # Find most similar tools
    similar_tools = vdb.search(query_vec, top_k=5)
    
    # Return only relevant tools to agent
    return similar_tools
```

### Cost Reduction

```
Goal: $0.80 → $0.45 per analysis (45% reduction)

Techniques:
1. Cache common queries (20% savings)
2. Use smaller models for simple tasks (15% savings)
3. Batch tool calls (10% savings)
4. Dynamic tool selection (5% savings)
5. Early termination if confidence high (5% savings)

Result: ~$0.45 per analysis
       = $450/month for 1000 analyses
       = Can charge $199 for premium feature (55% margin)
```

---

## 7. MONITORING & OBSERVABILITY

### Key Metrics

```yaml
execution_metrics:
  - latency_p50
  - latency_p95
  - latency_p99
  - tool_call_success_rate
  - agent_accuracy (from user feedback)
  - confidence_calibration

cost_metrics:
  - tokens_per_analysis
  - api_calls_per_analysis
  - cost_per_analysis
  - monthly_spend

quality_metrics:
  - user_rating_avg
  - recommendation_accuracy
  - recommendation_adoption_rate
  - complaint_rate

agent_metrics:
  - per-agent success rate
  - per-tool usage frequency
  - tool error rate
  - tool recommendation accuracy
```

### Monitoring Dashboard (Datadog)

```
Tiles:
- Execution Time Distribution
- Agent Success Rate Heatmap
- Cost per Analysis Trend
- User Rating Distribution
- Tool Usage Frequency
- Error Log Stream
- User Feedback Sentiment
```

---

## 8. ROLLOUT PLAN

### Week 1-2: Foundation
```
- Setup n8n infrastructure
- Setup Supabase database
- Implement orchestrator workflow
- Deploy 3 basic agents (news, fundamental, macro)
- Local testing only
```

### Week 3-4: Integration
```
- Connect to all 8 APIs
- Implement tool wrappers
- Add error handling
- Deploy to staging
- Internal testing with team
```

### Week 5-6: MVP
```
- Full 8 agent system
- All tools integrated
- Monitoring activated
- Beta test with 20 users
- Iterate based on feedback
```

### Week 7-8: Polish
```
- Performance optimization
- Cost reduction
- Prompt tuning
- User experience refinement
- Launch to public
```

---

## 9. SUCCESS CRITERIA

```
MVP Success (Week 6):
✅ System responds in < 5 seconds
✅ 80% of analyses rated 4+ stars
✅ Cost < $0.80 per analysis
✅ 95% agent success rate
✅ System handles 100 concurrent users

Production Success (Month 3):
✅ < 3 second response time
✅ 85%+ user satisfaction
✅ $0.45 cost per analysis
✅ 500+ active users
✅ $20K MRR from premium
```

---

**Build this. It will be revolutionary.**
